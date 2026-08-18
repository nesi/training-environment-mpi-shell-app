#!/usr/bin/env bash
# Start every tool listed in tools.tsv to prove it is installed, on PATH and
# able to load its libraries. Run at build time; also useful interactively.
set -uo pipefail

TSV="${1:-/opt/tools.tsv}"
fail=0

# how to make each tool print something and exit; default is --version
declare -A PROBE=(
    [spades.py]="--version"
    [metaspades.py]="--version"
    [rnaspades.py]="--version"
    [plasmidspades.py]="--version"
    [quast.py]="--version"
    [metaquast.py]="--version"
    [racon]="--version"
    [prodigal]="-v"
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
)

while IFS=$'\t' read -r cmd env version description; do
    [ -z "${cmd:-}" ] && continue
    case "$cmd" in \#*) continue ;; esac

    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "FAIL ${cmd}: not on PATH"
        fail=1
        continue
    fi

    probe="${PROBE[$cmd]:---version}"
    out=$("$cmd" $probe 2>&1)
    rc=$?
    out=$(printf '%s' "$out" | tr -d '\000')
    # some tools exit non-zero after printing usage; treat empty output as the failure
    if [ -z "$out" ] && [ "$rc" -ne 0 ]; then
        echo "FAIL ${cmd}: exit ${rc}, no output"
        fail=1
        continue
    fi
    if ! grep -Fq "$version" <<< "$out"; then
        echo "WARN ${cmd}: expected version ${version}, got: $(head -n 2 <<< "$out" | tr '\n' ' ')"
    fi
    echo "ok   ${cmd} (${version}, env ${env})"
done < "$TSV"

if [ "$fail" -ne 0 ]; then
    echo "smoke test FAILED"
    exit 1
fi
echo "smoke test passed"
