#!/bin/bash
echo $PWD 

  echo "Applying patches for ramips-mt7621/D-Link COVR X186x on gluon"
  patchfile="../patches/add-dlink-covr186x-gluon.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'covr' targets/ramips-mt7621
  pushd openwrt

  patchfile="../../patches/add-dlink-covr186x-openwrt2.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  popd