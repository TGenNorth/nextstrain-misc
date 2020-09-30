#!/bin/bash
dir=$(realpath $0)
dir=${dir%/*}
dir=${dir%/*}/

source /scratch/cfrench/miniconda3/etc/profile.d/conda.sh
conda activate nextstrain

sbatch \
  --job-name="misc_nexstrain-Augur" \
  --array="0-0%1" \
  --workdir="${dir}" \
  --output=${dir}log.txt \
  --cpus-per-task=16 \
  --time=5-00:00:00 \
  --mem=36gb \
  --wrap="snakemake -F --cores 16"
