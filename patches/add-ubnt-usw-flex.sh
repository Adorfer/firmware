#!/bin/bash
echo $PWD 

  echo "Applying patches for ramips-mt7621/Ubuiquiti USW-Flex"
  patchfile="../patches/ add-ubnt-usw-flex.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'usw-flex' targets/ramips-mt7621
