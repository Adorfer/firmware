#!/bin/bash
echo $PWD 

  echo "Applying patch for factory image for ramips-mt7621/genexis-ex400"
  patchfile="../patches/genexis-ex400-factoryimage.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep -A1 'genexis_pulse-ex400' targets/ramips-mt7621
