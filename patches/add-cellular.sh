#!/bin/bash
echo $PWD 
  echo "add Cellular-Device zte mf286r"
  patchfile="../patches/cellular.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi


