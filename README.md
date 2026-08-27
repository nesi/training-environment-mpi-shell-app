# REANNZ training environment for MPI Bioinformatics app

JupyterLab app for running the MPI Shell for Bioinformatics workshop on the NeSI training environment.

### Workshop Material
https://genomicsaotearoa.github.io/hts_workshop_mpi/

## Tools

Where the workshop uses a NeSI (mahuika) module, the tool is installed at that same
version. Every tool is on `PATH` in every shell and notebook terminal and is started by
typing its name. No `module load`, no `conda activate`, no `source` of an environment.

Run `mpi-tools` inside the app to print this table with descriptions.

Flye was removed in v0.4.0: it crashed on the workshop dataset both in this environment
and on NeSI. `raven` is the long read assembler used in its place, with `canu` available
as a more configurable alternative.

| Command | Version | NeSI module |
|---|---|---|
| `spades.py`, `metaspades.py`, `rnaspades.py`, `plasmidspades.py` | 3.15.2 | SPAdes/3.15.2-gimkl-2020a |
| `raven` | 1.8.3 | - |
| `canu` | 2.3 | - |
| `Bandage` | 0.9.0 | - |
| `quast.py`, `metaquast.py` | 5.2.0 | QUAST/5.2.0-gimkl-2022a |
| `minimap2` | 2.24 | minimap2/2.24-GCC-11.3.0 |
| `racon` | 1.5.0 | Racon/1.5.0-GCC-11.3.0 |
| `bowtie2`, `bowtie2-build`, `bowtie2-inspect` | 2.4.5 | Bowtie2/2.4.5-GCC-11.3.0 |
| `samtools` | 1.16.1 | SAMtools/1.16.1-GCC-11.3.0 |
| `prodigal` | 2.6.3 | prodigal/2.6.3-GCCcore-7.4.0 |
| `augustus`, `etraining`, `new_species.pl`, `gff2gbSmallDNA.pl`, `optimize_augustus.pl` | 3.5.0 | - |
| `blastn`, `blastp`, `blastx`, `tblastn`, `tblastx`, `makeblastdb`, `blastdbcmd` | 2.13.0 | BLAST/2.13.0-GCC-11.3.0 |
| `diamond` | 2.2.1 | DIAMOND/2.2.1-GCC-15.2.0 |
| `kraken2`, `kraken2-build`, `kraken2-inspect` | 2.1.3 | Kraken2/2.1.3-GCC-11.3.0 |
| `fastqc` | 0.12.1 | - |
| `fastp` | 1.0.1 | - |
| `seqkit` | 2.10.1 | - |
| `seqtk` | 1.4 | - |
| `porechop` | 0.2.4 | - |
| `NanoFilt` | 2.8.0 | - |
| `pycoQC` | 2.5.2 | - |

`bioawk`, `git`, `rsync`, `tree`, `vim`, `nano` and JupyterLab are also installed.

`module` still exists as a no-op that exits 0, so workshop material copied from mahuika
that still contains `module load` lines keeps running.

## How the tools are installed

The tools are installed with `micromamba` into five environments under `/opt/conda/envs`
(`docker/envs/*.yml`). Environments are split only because the pinned versions cannot
coexist in one solve:

* `assembly` - Raven, QUAST, minimap2, Racon, Bowtie2, SAMtools, prodigal, BLAST, Kraken2.
* `spades` - SPAdes 3.15.2 ships a vendored `pyyaml` that calls `collections.Hashable`,
  removed in Python 3.10, so it needs Python 3.9 while `assembly` solves to Python 3.10.
* `diamond` - DIAMOND 2.2.1 needs `zlib >= 1.3.2`, SAMtools 1.16.1 pins `zlib < 1.3`.
* `extras` - Canu, Bandage and Augustus, which need the same newer `zlib` as DIAMOND.
* `qc` - FastQC, fastp, SeqKit, seqtk, Porechop, NanoFilt, pycoQC.

The split is invisible to users: `docker/make-wrappers.sh` reads `docker/tools.tsv` and
writes one wrapper per command into `/usr/local/bin`. Each wrapper puts its own
environment's `bin` first on `PATH` and then execs the tool, so every tool starts the
same way and tools that call helper binaries (`spades-core`, `raven`, `kraken2-classify`)
still find them.

The wrappers do not run conda's activation scripts, so a tool that needs an environment
variable declares it in the fifth column of `docker/tools.tsv` as `KEY=VALUE` pairs
separated by semicolons (`-` when it needs none). Three tools use this:

* `Bandage` - `QT_QPA_PLATFORM=offscreen`, so it runs headless with no X server.
* `canu` - `JAVA_HOME`, pointing at the JDK inside the `extras` environment.
* `augustus` and its helper scripts - `AUGUSTUS_CONFIG_PATH`.

### Adding or changing a tool

1. Add or edit the pin in the relevant `docker/envs/*.yml`.
2. Add the command, environment, version, description and any extra environment
   variables to `docker/tools.tsv` (tab separated, five columns).
3. Rebuild. The build fails if a command listed in `tools.tsv` is not installed.

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
prediction (prodigal, Augustus), homology search (BLAST, DIAMOND), classification
(Kraken2 with a custom database built during the test) and read QC (FastQC, fastp,
SeqKit, seqtk, Porechop, NanoFilt, pycoQC).

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

Current release: **v0.4.0** (Raven replaces Flye; Canu, Bandage, Augustus and seqtk added).

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
   git tag -a v0.4.0 -m "v0.4.0: summary of the change" && git push origin v0.4.0
   ```

5. Wait for the tag's build to finish, then confirm the image is pullable:

   ``` bash
   docker pull ghcr.io/nesi/training-environment-mpi-shell-app:v0.4.0
   ```

6. Bump this app's version in the `training-environment` vars repo to deploy it.

Before tagging, check the version appears consistently in `submit.yml.erb`, this section
and — where the tool list changed — `manifest.yml`.
