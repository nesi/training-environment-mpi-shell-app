#!/usr/bin/env bash
# Start every tool listed in tools.tsv to prove it is installed, on PATH and
# able to load its libraries. Run at build time; also useful interactively.
#
# This is the check that catches an over-aggressive image cleanup: a tool whose
# shared libraries have been deleted still exists on PATH but dies on start.
set -uo pipefail

TSV="${1:-/opt/tools.tsv}"
VERSIONS="${2:-/opt/tool-versions.tsv}"
fail=0

declare -A VERSION=()
if [ -r "$VERSIONS" ]; then
    while IFS=$'\t' read -r cmd version; do
        [ -n "${cmd:-}" ] && VERSION["$cmd"]="$version"
    done < "$VERSIONS"
fi

# how to make each tool print something and exit; default is --version
declare -A PROBE=(
    [spades.py]="--version"
    [metaspades.py]="--version"
    [rnaspades.py]="--version"
    [plasmidspades.py]="--version"
    [quast.py]="--version"
    [metaquast.py]="--version"
    [racon]="--version"
    [canu]="-version"
    [prodigal]="-v"
    [augustus]="--version"
    [etraining]=""
    [new_species.pl]=""
    [gff2gbSmallDNA.pl]=""
    [optimize_augustus.pl]=""
    [blastn]="-version"
    [blastp]="-version"
    [blastx]="-version"
    [tblastn]="-version"
    [tblastx]="-version"
    [makeblastdb]="-version"
    [blastdbcmd]="-version"
    [kraken2]="--version"
    [kraken2-build]="--version"
    [kraken2-inspect]="--version"
    [bowtie2-inspect]="--version"
    [porechop]="--version"
    [NanoFilt]="--version"
    [pycoQC]="--version"
    [fastqc]="--version"
    [seqkit]="version"
    [seqtk]=""
)

# tools that never print their package version, so the version check is skipped:
# canu reports a git revision, the Augustus helper scripts print only usage.
declare -A NO_VERSION_STRING=(
    [canu]=1
    [etraining]=1
    [new_species.pl]=1
    [gff2gbSmallDNA.pl]=1
    [optimize_augustus.pl]=1
)

while IFS=$'\t' read -r cmd env package description extra_env; do
    [ -z "${cmd:-}" ] && continue
    case "$cmd" in \#*) continue ;; esac

    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "FAIL ${cmd}: not on PATH"
        fail=1
        continue
    fi

    probe="${PROBE[$cmd]---version}"
    out=$("$cmd" $probe 2>&1)
    rc=$?
    out=$(printf '%s' "$out" | tr -d '\000')

    # A tool that cannot start is a failure however it exits, and several exit 0
    # while printing the error. Two ways this has actually happened here:
    #   - deleting a shared library during the image cleanup (missing .so)
    #   - a Python tool importing pkg_resources, which left the stdlib in 3.13
    if grep -qiE "error while loading shared libraries|cannot open shared object|symbol lookup error" <<< "$out"; then
        echo "FAIL ${cmd}: $(head -n 1 <<< "$out")"
        fail=1
        continue
    fi
    if grep -qE "^Traceback \(most recent call last\)" <<< "$out"; then
        reason=$(grep -E '^[A-Za-z_.]*(Error|Exception):' <<< "$out" | head -n 1)
        echo "FAIL ${cmd}: ${reason:-python traceback on start}"
        fail=1
        continue
    fi
    # some tools exit non-zero after printing usage; treat empty output as the failure
    if [ -z "$out" ] && [ "$rc" -ne 0 ]; then
        echo "FAIL ${cmd}: exit ${rc}, no output"
        fail=1
        continue
    fi

    version="${VERSION[$cmd]:-?}"
    if [ -z "${NO_VERSION_STRING[$cmd]:-}" ] && [ "$version" != "?" ] \
       && ! grep -Fq "$version" <<< "$out"; then
        echo "WARN ${cmd}: conda installed ${version}, tool reports: $(head -n 2 <<< "$out" | tr '\n' ' ')"
    fi
    echo "ok   ${cmd} (${version}, env ${env})"
done < "$TSV"

if [ "$fail" -ne 0 ]; then
    echo "smoke test FAILED"
    exit 1
fi
echo "smoke test passed"
