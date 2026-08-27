# REANNZ training environment for MPI Bioinformatics app

JupyterLab app for running the MPI Shell for Bioinformatics workshop on the NeSI training environment.

### Workshop Material
https://genomicsaotearoa.github.io/hts_workshop_mpi/

## Tools

Nothing in this image is pinned. Versions are whatever conda resolved when the image
was built, and they are recorded in the image itself - run `mpi-tools` inside the app to
print the full table with the versions that image actually contains.

Every tool is on `PATH` in every shell and notebook terminal and is started by typing its
name. No `module load`, no `conda activate`, no `source` of an environment.

| Command | Purpose |
|---|---|
| `spades.py`, `metaspades.py`, `rnaspades.py`, `plasmidspades.py` | Short read assembly |
| `raven` | Long read assembly |
| `canu` | Long read assembly, more configurable |
| `Bandage` | Assembly graph inspection and rendering |
| `quast.py`, `metaquast.py` | Assembly quality assessment |
| `minimap2` | Long read alignment |
| `racon` | Consensus polishing |
| `bowtie2`, `bowtie2-build`, `bowtie2-inspect` | Short read alignment |
| `samtools` | SAM/BAM/CRAM manipulation |
| `prodigal` | Prokaryote gene prediction |
| `augustus`, `etraining`, `new_species.pl`, `gff2gbSmallDNA.pl`, `optimize_augustus.pl` | Eukaryote gene prediction |
| `blastn`, `blastp`, `blastx`, `tblastn`, `tblastx`, `makeblastdb`, `blastdbcmd` | Homology search |
| `diamond` | Fast protein alignment |
| `kraken2`, `kraken2-build`, `kraken2-inspect` | Taxonomic classification |
| `fastqc`, `fastp` | Read quality control and trimming |
| `seqkit`, `seqtk` | FASTA/FASTQ manipulation |
| `porechop`, `NanoFilt`, `pycoQC` | Nanopore read QC |

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
prediction (prodigal, Augustus), homology search (BLAST, DIAMOND), classification
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

Current release: **v0.5.0** (single conda environment, no version pins; image reduced from 6.13 GB to 4.50 GB).

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
   git tag -a v0.5.0 -m "v0.5.0: summary of the change" && git push origin v0.5.0
   ```

5. Wait for the tag's build to finish, then confirm the image is pullable:

   ``` bash
   docker pull ghcr.io/nesi/training-environment-mpi-shell-app:v0.5.0
   ```

6. Bump this app's version in the `training-environment` vars repo to deploy it.

Before tagging, check the version appears consistently in `submit.yml.erb`, this section
and — where the tool list changed — `manifest.yml`.
