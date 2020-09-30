#!/bin/bash
dir=$(realpath $0)
dir=${dir%/*}
dir=${dir%/*}/genome-sampler/

if [ -d ${dir} ]; then
  if [ -d ${dir}.snakemake ]; then
    rm -r ${dir}.snakemake
  fi
  if [ -f ${dir}sequences.fasta ]; then
    rm ${dir}sequences.fasta
  fi
  while read line; do
    if [[ ${line} == *".qza" ]] || [[ ${line} == *".qzv" ]]; then
      rm ${dir}${line}
    fi
  done < <(ls ${dir})
fi
