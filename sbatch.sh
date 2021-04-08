#!/bin/bash
#SBATCH --job-name NextstrainWeekly_AZ_test
#SBATCH --workdir=/scratch/cfrench/COV/Nextstrain/Weekly/AZ_test
#SBATCH --output=/scratch/cfrench/COV/Nextstrain/Weekly/AZ_test/slurmout.txt
#SBATCH --export=ALL
#SBATCH --cpus-per-task=40
#SBATCH --time=5-00:00:00
#SBATCH --mem=150gb

export AUGUR_RECURSION_LIMIT=50000
echo "limit: $AUGUR_RECURSION_LIMIT"
snakemake -F --cores 40
