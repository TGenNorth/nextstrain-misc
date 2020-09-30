#!/bin/bash
dir=$(realpath $0)
dir=${dir%/*}
dir=${dir%/*}/

if [ -d ${dir} ]; then
  if [ -d ${dir}.snakemake ]; then
    rm -r ${dir}.snakemake
  fi
fi
