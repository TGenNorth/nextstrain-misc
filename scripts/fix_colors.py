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

  #..... read metadata
  metadata = list(map(lambda x: x.split("\t"), read(sys.argv[1]).split("\n")))
  # metaHeader <- ['id', 'strain', 'virus', 'gisaid_epi_isl', 'gisaid_id', 'date', 'region', 'country', 'division', 'location', 'lineage', 'bootstrap', 'az']
  metaHeader = metadata.pop(0)

  #..... get colors
  colorFile = []
  colorSchemes = list(map(lambda x: x.split("\t"), read(sys.argv[2]).split("\n")))

  #..... get metadata
  metadata = list(filter(lambda x: len(x) == len(metaHeader), metadata))
  colorHash = {}
  for head in metaHeader:
    colorHash[head] = []

  for line in metadata:
    for head in metaHeader:
      if line[metaHeader.index(head)]:
        colorHash[head].append(line[metaHeader.index(head)])

  for head in sorted(colorHash):
    colorHash[head] = list(set(colorHash[head]))
    if len(colorHash[head]) <= len(colorSchemes[-1]):
      colorFile.append("")
      if not list(filter(lambda x: len(x) == len(colorHash[head]), colorSchemes)):
        continue
      colorScheme = list(filter(lambda x: len(x) == len(colorHash[head]), colorSchemes))[0]
      #print(head, colorHash[head], colorScheme)
      for i in range(len(colorHash[head])):
        colorFile.append("\t".join([head, sorted(colorHash[head])[i], colorScheme[i]]))

  colorFile = sorted(list(set(filter(lambda x: x, colorFile))))
  #for line in colorFile:
  #  print(line)

  write(sys.argv[3], "\n".join(colorFile))

      
    


if __name__ == "__main__":
  main()
