#!/usr/bin/env python3

import sys 
import os
import subprocess
import json
import re
import random

#====================================================================================================( functions )
#--------------------------------------------------( File I/O )
def read(fileName):
  try:
    f = open(fileName, 'r')
    file = f.read()
    f.close
  except:
    f = open(fileName, 'r', encoding = "ISO-8859-1")
    file = f.read()
    f.close
  return file

def write(fileName, output):
  f = open(fileName, 'w')
  f.write(output)
  f.close()

#====================================================================================================( main )
def main():
  counties = ["apache", "cochise", "coconino", "gila", "graham", "greenlee", "la paz", "maricopa", "mohave", "navajo", "pima", "pinal", "santa cruz", "yavapai", "yuma"]

  #..... read metadata
  metadata = list(map(lambda x: x.split("\t"), read(sys.argv[1]).split("\n")))
  # metaHeader <- ['id', 'strain', 'virus', 'gisaid_epi_isl', 'gisaid_id', 'date', 'region', 'country', 'division', 'location', 'lineage', 'bootstrap', 'az']
  metaHeader = metadata.pop(0)

  #..... fix county names (ensure names are synced to list is from Arizona)
  for i in range(len(metadata)):
    if metadata[i][metaHeader.index("division")].lower() in ["az", "arizona"]:

      # lower, replace/remove junk
      metadata[i][metaHeader.index("location")] = metadata[i][metaHeader.index("location")].lower()
      for c in ["-", "_"]:
        metadata[i][metaHeader.index("location")] = " ".join(metadata[i][metaHeader.index("location")].split(c))
      for c in ["county", "co."]:
        metadata[i][metaHeader.index("location")] = "".join(metadata[i][metaHeader.index("location")].split(c)).strip()
      if metadata[i][metaHeader.index("location")] in counties:
        metadata[i][metaHeader.index("location")] = "_".join(metadata[i][metaHeader.index("location")].title().split(" ")) + "_County"

      # correct common wrong names
      elif metadata[i][metaHeader.index("location")] == "phoenix":
        metadata[i][metaHeader.index("location")] = "Maricopa_County"
      elif metadata[i][metaHeader.index("location")] == "tucson":
        metadata[i][metaHeader.index("location")] = "Pima_County"

      # remove altogether if in Arizona state, but wrong county
      else:
        metadata[i][metaHeader.index("location")] = ""

  write(sys.argv[2], "\n".join(list(map(lambda x: "\t".join(x), [metaHeader] + metadata))))


if __name__ == "__main__":
  main()
