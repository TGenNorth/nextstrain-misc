#!/bin/bash
dir=$(realpath $0)
dir=${dir%/*}
dir=${dir%/*}/genome-sampler/

source /scratch/cfrench/miniconda3/etc/profile.d/conda.sh
conda activate genome-sampler

sbatch \
  --job-name="misc_genome-sampler" \
  --array="0-0%1" \
  --workdir="${dir}" \
  --output=${dir}log.txt \
  --partition="hmem" \
  --cpus-per-task=40 \
  --time=5-00:00:00 \
  --mem=36gb \
  --wrap="snakemake -F --cores 40"
