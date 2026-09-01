#!/usr/bin/env bash
# End-to-end check that every tool in this image does real work, not just
# --version. Builds a small synthetic dataset, then runs the whole workshop
# pipeline through it. Takes a couple of minutes.
#
#   docker run --rm <image> bash /opt/functional-test.sh
#
# The build-time check is smoke-test.sh; this one is deliberately not run
# during the build because of its runtime.
set -uo pipefail

WORKDIR="${1:-/tmp/functional-test}"
rm -rf "$WORKDIR" && mkdir -p "$WORKDIR" && cd "$WORKDIR"
fail=0
check(){ if [ $1 -eq 0 ]; then echo "PASS $2"; else echo "FAIL $2"; fail=1; fi; }

python3 - <<'PY'
import random
random.seed(7)
g="".join(random.choice("ACGT") for _ in range(30000))
open("ref.fa","w").write(">ref\n"+"\n".join(g[i:i+70] for i in range(0,len(g),70))+"\n")
# paired short reads with perfect coverage
r1=open("r1.fq","w"); r2=open("r2.fq","w")
def qual(n):
    return "".join(chr(33+random.randint(20,40)) for _ in range(n))
def mut(s, rate=0.005):
    s=list(s)
    for j in range(len(s)):
        if random.random()<rate:
            s[j]=random.choice("ACGT")
    return "".join(s)
for n in range(8000):
    ins=random.randint(300,500)
    start=random.randint(0,len(g)-ins)
    frag=g[start:start+ins]
    a=mut(frag[:150])
    b=mut(frag[-150:])
    rc=b[::-1].translate(str.maketrans("ACGT","TGCA"))
    r1.write(f"@rd{n}/1\n{a}\n+\n{qual(len(a))}\n"); r2.write(f"@rd{n}/2\n{rc}\n+\n{qual(len(rc))}\n")
r1.close(); r2.close()
# long reads: varied lengths and start positions, ~40x coverage, 1% error
lr=open("long.fq","w")
i=0
for _ in range(250):
    L=random.randint(3000,8000)
    start=random.randint(0,len(g)-L)
    s=list(g[start:start+L])
    for j in range(len(s)):
        if random.random()<0.01:
            s[j]=random.choice("ACGT")
    s="".join(s)
    lr.write(f"@lr{i}\n{s}\n+\n{''.join(chr(33+random.randint(10,30)) for _ in s)}\n"); i+=1
lr.close()
open("prot.faa","w").write(">p1\nMKTIIALSYIFCLVFADYKDDDDKGGSGGMKAVLLNRQWALIGASLFGAK\n")
PY
check $? "generate test data"

seqkit stats ref.fa r1.fq long.fq > seqkit.txt 2>&1;            check $? "seqkit stats"
seqtk seq -A long.fq > long.fa 2>seqtk.log;                      check $? "seqtk fastq to fasta"
test -s long.fa;                                                 check $? "seqtk fasta produced"
fastp -i r1.fq -I r2.fq -o t1.fq -O t2.fq -j fastp.json -h fastp.html > fastp.log 2>&1; check $? "fastp paired trim"
fastqc -q -o . r1.fq > fastqc.log 2>&1;                          check $? "fastqc"
NanoFilt -q 5 -l 500 < long.fq > long.filt.fq 2>nanofilt.log;    check $? "NanoFilt"
porechop -i long.fq -o long.chop.fq --threads 4 > porechop.log 2>&1; check $? "porechop"

spades.py -1 r1.fq -2 r2.fq -o spades_out -t 8 -m 8 > spades.log 2>&1; check $? "spades.py assembly"
test -s spades_out/contigs.fasta;                                check $? "spades contigs produced"

raven --threads 4 --graphical-fragment-assembly raven.gfa long.fq > raven.fa 2>raven.log; check $? "raven assembly"
test -s raven.fa;                                                check $? "raven contigs produced"
test -s raven.gfa;                                               check $? "raven assembly graph produced"

Bandage info raven.gfa > bandage.info 2>bandage.log;             check $? "Bandage info"
Bandage image raven.gfa raven.png >> bandage.log 2>&1;           check $? "Bandage image"
test -s raven.png;                                               check $? "Bandage png produced"

# canu is the configurable alternative to raven; -fast and the low coverage
# thresholds keep it inside a couple of minutes on this toy dataset
canu -p canu -d canu_out genomeSize=30k -fast useGrid=false \
     maxThreads=4 maxMemory=8g minInputCoverage=1 stopOnLowCoverage=1 \
     -nanopore long.fq > canu.log 2>&1;                          check $? "canu assembly"
test -s canu_out/canu.contigs.fasta;                             check $? "canu contigs produced"

quast.py -o quast_out -r ref.fa spades_out/contigs.fasta > quast.log 2>&1; check $? "quast.py"
test -s quast_out/report.txt;                                    check $? "quast report produced"

minimap2 -x map-ont ref.fa long.fq > ovl.paf 2>mm2.log;          check $? "minimap2 paf"
minimap2 -ax map-ont ref.fa long.fq > aln.sam 2>>mm2.log;        check $? "minimap2 sam"
racon long.fq ovl.paf ref.fa > polished.fa 2>racon.log;          check $? "racon polish"

bowtie2-build ref.fa refidx > bt2build.log 2>&1;                 check $? "bowtie2-build"
bowtie2 -x refidx -1 r1.fq -2 r2.fq -S bt2.sam -p 4 > bt2.log 2>&1; check $? "bowtie2 align"

samtools sort -o bt2.bam bt2.sam > st.log 2>&1;                  check $? "samtools sort"
samtools index bt2.bam >> st.log 2>&1;                           check $? "samtools index"
samtools flagstat bt2.bam > flagstat.txt 2>>st.log;              check $? "samtools flagstat"

prodigal -i ref.fa -a genes.faa -d genes.fna -o genes.gbk > prodigal.log 2>&1; check $? "prodigal genes"
test -s genes.faa;                                               check $? "prodigal proteins produced"

# augustus finds exactly one gene in this random 30kb sequence. The seed above is
# fixed, so that is stable - but if the generator changes and augustus predicts
# nothing, the getAnnoFasta.pl checks below fail with empty output rather than an
# error, because there are no sequence comments to convert.
augustus --species=human --codingseq=on ref.fa > augustus.gff 2>augustus.log; check $? "augustus gene prediction"
test -s augustus.gff;                                            check $? "augustus gff produced"
grep -q $'\tgene\t' augustus.gff;                                check $? "augustus predicted at least one gene"

# getAnnoFasta.pl turns the sequence comments in the augustus output into fasta
getAnnoFasta.pl augustus.gff > getannofasta.log 2>&1;            check $? "getAnnoFasta.pl"
test -s augustus.aa;                                             check $? "getAnnoFasta.pl proteins produced"
test -s augustus.codingseq;                                      check $? "getAnnoFasta.pl coding seqs produced"

makeblastdb -in ref.fa -dbtype nucl -out refdb > blast.log 2>&1; check $? "makeblastdb"
blastn -query ref.fa -db refdb -outfmt 6 -out blastn.tsv >> blast.log 2>&1; check $? "blastn"
test -s blastn.tsv;                                              check $? "blastn hits produced"

diamond makedb --in prot.faa -d protdb > diamond.log 2>&1;       check $? "diamond makedb"
diamond blastp -q prot.faa -d protdb -o dmnd.tsv >> diamond.log 2>&1; check $? "diamond blastp"
test -s dmnd.tsv;                                                check $? "diamond hits produced"

# kraken2 against a tiny custom database built from the reference
mkdir -p kdb/taxonomy
printf '1\t|\t1\t|\tno rank\t|\t-\t|\n2\t|\t1\t|\tspecies\t|\t-\t|\n' > kdb/taxonomy/nodes.dmp
printf '1\t|\troot\t|\t-\t|\tscientific name\t|\n2\t|\ttestbug\t|\t-\t|\tscientific name\t|\n' > kdb/taxonomy/names.dmp
sed 's/>ref/>ref|kraken:taxid|2/' ref.fa > ref.tax.fa
kraken2-build --add-to-library ref.tax.fa --db kdb > kraken.log 2>&1 && \
kraken2-build --build --db kdb --threads 4 >> kraken.log 2>&1;   check $? "kraken2-build custom db"
kraken2 --db kdb --report kraken.report long.fq > kraken.out 2>>kraken.log; check $? "kraken2 classify"
test -s kraken.report;                                           check $? "kraken2 report produced"

echo "-----"
[ $fail -eq 0 ] && echo "FUNCTIONAL TESTS PASSED" || echo "FUNCTIONAL TESTS FAILED"
exit $fail
