# REANNZ training environment for MPI Bioinformatics app

JupyterLab app for running the MPI Shell for Bioinformatics workshop on the NeSI training environment.

### Workshop Material
https://genomicsaotearoa.github.io/hts_workshop_mpi/

## Tools

Almost nothing is pinned. Versions are whatever conda resolved when the image was built,
and each image records its own - run `mpi-tools` inside the app to print the table with
the versions that image actually contains. The one exception is Augustus, held at 3.5 or
newer because older builds drop the perl helper scripts the workshop uses.

Every tool is on `PATH` in every shell and notebook terminal and is started by typing its
name. No `module load`, no `conda activate`, no `source` of an environment.

Two changes to the long read assemblers, both at MPI's request. Flye was removed in
v0.4.0 after it crashed on the workshop dataset here and on NeSI; `raven` replaced it.
Canu was removed in v0.6.0 - it was there for trainees wanting to extend themselves, and
they can reach it through NeSI outside the training session instead.

| Command | Version in v0.6.0 | Purpose |
|---|---|---|
| `spades.py`, `metaspades.py`, `rnaspades.py`, `plasmidspades.py` | 4.3.0 | Short read assembly |
| `raven` | 1.8.3 | Long read assembly |
| `Bandage` | 0.9.0 | Assembly graph inspection and rendering |
| `quast.py`, `metaquast.py` | 5.3.0 | Assembly quality assessment |
| `minimap2` | 2.31 | Long read alignment |
| `racon` | 1.5.0 | Consensus polishing |
| `bowtie2`, `bowtie2-build`, `bowtie2-inspect` | 2.5.5 | Short read alignment |
| `samtools` | 1.23 | SAM/BAM/CRAM manipulation |
| `prodigal` | 2.6.3 | Prokaryote gene prediction |
| `augustus`, `etraining`, `new_species.pl`, `gff2gbSmallDNA.pl`, `optimize_augustus.pl`, `getAnnoFasta.pl` | 3.5.0 | Eukaryote gene prediction |
| `blastn`, `blastp`, `blastx`, `tblastn`, `tblastx`, `makeblastdb`, `blastdbcmd` | 2.16.0 | Homology search |
| `diamond` | 2.2.5 | Fast protein alignment |
| `kraken2`, `kraken2-build`, `kraken2-inspect` | 2.17.1 | Taxonomic classification |
| `fastqc` | 0.12.1 | Read quality control |
| `fastp` | 1.3.6 | Read trimming and filtering |
| `seqkit` | 2.13.0 | FASTA/FASTQ manipulation |
| `seqtk` | 1.5 | FASTA/FASTQ manipulation |
| `porechop` | 0.2.4 | Nanopore adapter trimming |
| `NanoFilt` | 2.8.0 | Nanopore read filtering |
| `pycoQC` | 2.5.0.3 | Nanopore run QC report |

The versions above are the ones the v0.6.0 image resolved to. Nothing is pinned, so a
later image may differ - `mpi-tools` inside the app always prints what that image really
contains, and is the version of record.

`bioawk`, `git`, `rsync`, `tree`, `vim`, `nano` and JupyterLab are also installed.

`module` still exists as a no-op that exits 0, so workshop material copied from mahuika
that still contains `module load` lines keeps running.

### Versions are no longer matched to mahuika

Earlier images pinned every tool to the version of the matching NeSI (mahuika) module.
Those pins could not co-exist in a single conda solve, so the tools were split across
five environments, and the dependencies each one duplicated cost roughly a gigabyte.

Dropping the pins collapsed that to one environment and, together with the build cleanup
below, took the image from 6.13 GB to 4.50 GB. The trade is that versions drift:
rebuilding six months from now may not produce the same versions as today. Because the
workshop app is pinned to a tagged image, a given tag stays fixed once built - the drift
only appears when a new image is built.

If a workshop exercise genuinely depends on a specific version, pin that one tool in
`docker/envs/bio.yml` and rebuild. Expect a single pin to be enough to force the
environment apart again, so pin only what is actually needed.

Removing a tool can move the others. Dropping Canu in v0.6.0 changed the solve enough
that Augustus fell back from 3.5.0 to 3.2.2, an old build that ships only `augustus` and
`etraining` - the perl helper scripts simply vanish. Nothing errors: the packages install
cleanly and the commands are missing afterwards. The build catches it because
`make-wrappers.sh` fails on any command in `tools.tsv` that is not present, which is why
`augustus >=3.5` is now in `bio.yml`. Re-check `mpi-tools` output after changing the tool
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
separated by semicolons (`-` when it needs none). Two tools use this:

* `Bandage` - `QT_QPA_PLATFORM=offscreen`, so it runs headless with no X server.
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

The functional test covers assembly (SPAdes, Raven), assembly graph rendering
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
augustus --species=human --codingseq=on contigs.fasta > genes.gff
getAnnoFasta.pl genes.gff          # writes genes.aa and genes.codingseq
new_species.pl --species=mybug
etraining --species=mybug training.gb
```

`getAnnoFasta.pl` turns the sequence comments Augustus writes into its output into fasta
files. Augustus emits protein comments by default; add `--codingseq=on` to get the
coding sequences as well.

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

Current release: **v0.6.0** (Canu removed, `getAnnoFasta.pl` exposed).

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
