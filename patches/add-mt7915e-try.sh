#!/bin/bash
echo $PWD 
  echo "Applying patches for MT7603 / MT7612"
  patchfile="../patches/mt7915e-try.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  popd