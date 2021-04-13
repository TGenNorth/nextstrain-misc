#!/bin/bash
export AUGUR_RECURSION_LIMIT=50000
export AUGUR_DIR=$(realpath ${0%/*})

JOBID=$(sbatch \
  --job-name="Nextstrain_${AUGUR_DIR##*/}" \
  --workdir="${AUGUR_DIR}" \
  --output="${AUGUR_DIR}/slurmout.txt" \
  --export="ALL" \
  --cpus-per-task="40" \
  --time="5-00:00:00" \
  --mem="150gb" \
  --wrap="echo limit: ${AUGUR_RECURSION_LIMIT}; echo job-name: Nextstrain_${AUGUR_DIR##*/}; snakemake -F --cores 40" \
)

# snakemake -R export --cores 40
