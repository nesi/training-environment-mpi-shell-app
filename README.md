# REANNZ training environment for MPI Bioinformatics app

JupyterLab app for running the MPI Shell for Bioinformatics workshop on the NeSI training environment.

### Workshop Material
https://genomicsaotearoa.github.io/hts_workshop_mpi/

## Tools

Every tool is on `PATH` in every shell and notebook terminal and is started by typing its
name. No `module load`, no `conda activate`, no `source` of an environment. Run
`mpi-tools` inside the app to print this table with the versions that image contains.

Almost nothing is pinned - versions are whatever conda resolved when the image was built.
The one exception is Augustus, held at 3.5 or newer because older builds drop the perl
helper scripts the workshop uses.

Flye was removed in v0.4.0 after it crashed on the workshop dataset here and on NeSI;
`raven` replaced it, with `canu` as the more configurable alternative.

### Assembly

| Command | Version | Example |
|---|---|---|
| `spades.py` | 4.3.0 | `spades.py -1 r1.fq -2 r2.fq -o out -t 8` |
| `metaspades.py` | 4.3.0 | `metaspades.py -1 r1.fq -2 r2.fq -o out` |
| `rnaspades.py` | 4.3.0 | `rnaspades.py -1 r1.fq -2 r2.fq -o out` |
| `plasmidspades.py` | 4.3.0 | `plasmidspades.py -1 r1.fq -2 r2.fq -o out` |
| `raven` | 1.8.3 | `raven -t 8 --graphical-fragment-assembly asm.gfa reads.fq > asm.fa` |
| `canu` | 2.3 | `canu -p run -d out genomeSize=5m -nanopore reads.fq` |
| `Bandage` | 0.9.0 | `Bandage info asm.gfa` / `Bandage image asm.gfa asm.png` |

### Assembly QA, mapping and polishing

| Command | Version | Example |
|---|---|---|
| `quast.py` | 5.3.0 | `quast.py -o out -r ref.fa contigs.fasta` |
| `metaquast.py` | 5.3.0 | `metaquast.py -o out contigs.fasta` |
| `minimap2` | 2.31 | `minimap2 -ax map-ont ref.fa reads.fq > aln.sam` |
| `racon` | 1.5.0 | `racon reads.fq overlaps.paf contigs.fa > polished.fa` |
| `bowtie2-build` | 2.5.5 | `bowtie2-build ref.fa refidx` |
| `bowtie2` | 2.5.5 | `bowtie2 -x refidx -1 r1.fq -2 r2.fq -S aln.sam` |
| `bowtie2-inspect` | 2.5.5 | `bowtie2-inspect -s refidx` |
| `samtools` | 1.23 | `samtools sort -o aln.bam aln.sam` then `samtools index aln.bam` |

### Gene prediction

| Command | Version | Example |
|---|---|---|
| `prodigal` | 2.6.3 | `prodigal -i contigs.fa -a genes.faa -d genes.fna -o genes.gbk` |
| `augustus` | 3.5.0 | `augustus --species=human --codingseq=on contigs.fa > genes.gff` |
| `getAnnoFasta.pl` | 3.5.0 | `getAnnoFasta.pl genes.gff` - writes `genes.aa` and `genes.codingseq` |
| `etraining` | 3.5.0 | `etraining --species=mybug training.gb` |
| `new_species.pl` | 3.5.0 | `new_species.pl --species=mybug` |
| `gff2gbSmallDNA.pl` | 3.5.0 | `gff2gbSmallDNA.pl genes.gff genome.fa 1000 training.gb` |
| `optimize_augustus.pl` | 3.5.0 | `optimize_augustus.pl --species=mybug training.gb` |

### Homology search and classification

| Command | Version | Example |
|---|---|---|
| `makeblastdb` | 2.16.0 | `makeblastdb -in ref.fa -dbtype nucl -out refdb` |
| `blastn` | 2.16.0 | `blastn -query q.fa -db refdb -outfmt 6 -out hits.tsv` |
| `blastp` | 2.16.0 | `blastp -query prot.faa -db protdb -outfmt 6` |
| `blastx` | 2.16.0 | `blastx -query q.fa -db protdb -outfmt 6` |
| `tblastn` | 2.16.0 | `tblastn -query prot.faa -db refdb -outfmt 6` |
| `tblastx` | 2.16.0 | `tblastx -query q.fa -db refdb -outfmt 6` |
| `blastdbcmd` | 2.16.0 | `blastdbcmd -db refdb -entry all -outfmt "%t"` |
| `diamond` | 2.2.5 | `diamond makedb --in prot.faa -d protdb` then `diamond blastp -q q.faa -d protdb -o hits.tsv` |
| `kraken2` | 2.17.1 | `kraken2 --db mydb --report k.report reads.fq > k.out` |
| `kraken2-build` | 2.17.1 | `kraken2-build --build --db mydb --threads 4` |
| `kraken2-inspect` | 2.17.1 | `kraken2-inspect --db mydb` |

### Read QC and manipulation

| Command | Version | Example |
|---|---|---|
| `fastqc` | 0.12.1 | `fastqc -o qc_out reads.fq` |
| `fastp` | 1.3.6 | `fastp -i r1.fq -I r2.fq -o t1.fq -O t2.fq -h fastp.html` |
| `seqkit` | 2.13.0 | `seqkit stats reads.fq` |
| `seqtk` | 1.5 | `seqtk seq -A reads.fq > reads.fa` |
| `porechop` | 0.2.4 | `porechop -i reads.fq -o trimmed.fq --threads 4` |
| `NanoFilt` | 2.8.0 | `NanoFilt -q 10 -l 500 < reads.fq > filtered.fq` |
| `pycoQC` | 2.5.0.3 | `pycoQC -f sequencing_summary.txt -o pycoqc.html` |

Versions above are what the v0.6.0 image resolved to. Nothing but Augustus is pinned, so
a later image may differ - `mpi-tools` is the version of record.

`bioawk`, `git`, `rsync`, `tree`, `vim`, `nano` and JupyterLab are also installed.

`module` still exists as a no-op that exits 0, so workshop material copied from mahuika
that still contains `module load` lines keeps running.

### Versions are not matched to mahuika

Earlier images pinned every tool to the version of the matching NeSI (mahuika) module.
Those pins could not co-exist in a single conda solve, so the tools were split across
five environments, and the dependencies each one duplicated cost roughly a gigabyte.

Dropping the pins collapsed that to one environment and, together with the build cleanup
below, took the image from 6.13 GB to about 4.4 GB. The trade is that versions drift:
rebuilding six months from now may not produce the same versions as today. Because the
workshop app is pinned to a tagged image, a given tag stays fixed once built - the drift
only appears when a new image is built.

If a workshop exercise genuinely depends on a specific version, pin that one tool in
`docker/envs/bio.yml` and rebuild. Pin only what is actually needed.

Removing a tool can move the others. Dropping Canu during v0.6.0 development changed the
solve enough that Augustus fell back from 3.5.0 to 3.2.2, an old build that ships only
`augustus` and `etraining` - the perl helper scripts simply vanish. Nothing errors: the
packages install cleanly and the commands are missing afterwards. The build catches it
because `make-wrappers.sh` fails on any command in `tools.tsv` that is not present, which
is why `augustus >=3.5` is pinned. Re-check `mpi-tools` output after changing the tool
list.

## How the tools are installed

Every tool is installed with `micromamba` into a single environment,
`/opt/conda/envs/bio`, from `docker/envs/bio.yml`.

`docker/make-wrappers.sh` reads `docker/tools.tsv` and writes one wrapper per command
into `/usr/local/bin`. Each wrapper puts the environment's `bin` first on `PATH` and then
execs the tool, so every tool starts the same way and tools that call helper binaries
(`spades-core`, `kraken2-classify`) still find them.

The same script records the version each conda package actually resolved to in
`/opt/tool-versions.tsv`. That file is what `mpi-tools` prints and what `smoke-test.sh`
checks against, so neither can report a version the image does not contain.

The wrappers do not run conda's activation scripts, so a tool that needs an environment
variable declares it in the fifth column of `docker/tools.tsv` as `KEY=VALUE` pairs
separated by semicolons (`-` when it needs none). Three tools use this:

* `Bandage` - `QT_QPA_PLATFORM=offscreen`, so it runs headless with no X server.
* `canu` - `JAVA_HOME`, pointing at the JDK inside the environment.
* `augustus` and its helper scripts - `AUGUSTUS_CONFIG_PATH`.

### Image size

The build deletes what only a compiler needs: C/C++ headers, static archives (`*.a`),
man pages and `share/doc`. Augustus depends on `libboost-devel`, which otherwise drags a
full sysroot and header tree into an image that never compiles anything.

Shared libraries are deliberately left alone. The conda toolchain directory holds the
boost `.so` files Augustus links against at run time, so deleting that directory
wholesale leaves `augustus` on `PATH` but unable to start. `smoke-test.sh` runs straight
after the cleanup and fails the build if any tool cannot start, which is what catches
this class of mistake.

### Adding or changing a tool

1. Add the package to `docker/envs/bio.yml`. Leave it unpinned unless a workshop exercise
   depends on a specific version.
2. Add the command, environment, conda package name, description and any extra
   environment variables to `docker/tools.tsv` (tab separated, five columns).
3. Rebuild. The build fails if a command listed in `tools.tsv` is not installed, if its
   conda package is not installed, or if any tool cannot start.

## Testing the image

```bash
docker build -t mpi-shell:test docker

# runs during the build as well: starts every command in tools.tsv
docker run --rm mpi-shell:test bash /opt/smoke-test.sh

# end-to-end, ~3 min: builds a synthetic dataset and runs the whole pipeline
docker run --rm mpi-shell:test bash /opt/functional-test.sh
```

The functional test covers assembly (SPAdes, Raven, Canu), assembly graph rendering
(Bandage), QA (QUAST), mapping and polishing (minimap2, Racon, Bowtie2, SAMtools), gene
prediction (prodigal, Augustus, getAnnoFasta.pl), homology search (BLAST, DIAMOND), classification
(Kraken2 with a custom database built during the test) and read QC (FastQC, fastp,
SeqKit, seqtk, Porechop, NanoFilt, pycoQC).

Run it after any change to the tool set or to the image cleanup. The build-time smoke
test proves each tool starts; only the functional test proves they still do real work.

## Kraken2 database

No Kraken2 database is bundled - the standard databases are tens of GB. Either build a
small custom one during the workshop:

```bash
kraken2-build --download-taxonomy --db mydb
kraken2-build --add-to-library my_genomes.fa --db mydb
kraken2-build --build --db mydb --threads 4
kraken2 --db mydb reads.fq --report kraken.report
```

or upload a prebuilt database the same way as the workshop dataset (below) and point
`--db` at it.

## Bandage and Augustus

There is no X server in the container, so `Bandage` runs headless: it writes image files
instead of opening a window. Both subcommands work on the assembly graph a long read
assembler produces.

```bash
raven --graphical-fragment-assembly assembly.gfa reads.fq > assembly.fasta
Bandage info assembly.gfa
Bandage image assembly.gfa assembly.png --height 1000
```

Augustus finds its species parameters through `AUGUSTUS_CONFIG_PATH`, which the wrapper
sets to `/opt/conda/envs/extras/config`. That directory is writable, so `new_species.pl`
and `etraining` can add a species during the workshop:

```bash
augustus --species=human contigs.fasta > genes.gff
new_species.pl --species=mybug
etraining --species=mybug training.gb
```

## Manual changes after deployment

The dataset is large (~2Gb), is not stored in git or in the container image, and requires
manual upload. Log in as `trainer1`, upload a tar.gz of the workshop material, then copy
it to the training accounts:

``` bash
for i in $(seq 1 10)
do
    echo copying to training$i
    cp level1.tar.gz /home/shared/training$i
    tar -xzf /home/shared/training$i/level1.tar.gz -C /home/shared/training$i
    rm /home/shared/training$i/level1.tar.gz
    chmod -R go+rw /home/shared/training$i/level1
done
```

Permissions for `trainer` accounts don't allow the copying, so every trainer account must
upload and then run the following.

``` bash
tar -xzf /home/shared/trainer1/level1.tar.gz -C /home/shared/trainer1
rm /home/shared/trainer1/level1.tar.gz
```

## Releasing

Current release: **v0.6.0** (`getAnnoFasta.pl` exposed on PATH; Augustus pinned to >=3.5).

Any push to `main` builds the image and pushes it to
`ghcr.io/nesi/training-environment-mpi-shell-app`. A tag push builds and publishes that
tag as well, which is what the app is pinned to.

To cut a release:

1. Open a pull request; the branch build must pass before merging.
2. Bump the image tag in `submit.yml.erb` and the version named in this section to the
   version you are about to release. Do this **in the pull request**, so that the tag you
   create points at a commit that already carries the right version.
3. Merge to `main`.
4. Tag `main` and push the tag:

   ``` bash
   git checkout main && git pull --ff-only
   git tag -a v0.6.0 -m "v0.6.0: summary of the change" && git push origin v0.6.0
   ```

5. Wait for the tag's build to finish, then confirm the image is pullable:

   ``` bash
   docker pull ghcr.io/nesi/training-environment-mpi-shell-app:v0.6.0
   ```

6. Bump this app's version in the `training-environment` vars repo to deploy it.

Before tagging, check the version appears consistently in `submit.yml.erb`, this section
and — where the tool list changed — `manifest.yml`.
