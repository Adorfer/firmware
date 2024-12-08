#!/bin/bash
echo $PWD 

if [ "$1" == "ramips-mt7621" ] 
 then
  echo "Applying patches for ramips-mt7621/mi-router-4a-gigabit on openwrt"
  cd openwrt 
  patchfile="../../patches/mi4ag-migration.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
 fi