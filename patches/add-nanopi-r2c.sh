#!/bin/bash
echo $PWD 

  echo "Applying patches for rockchip/nanopi-r3c"
  patchfile="../patches/ add-nanopi-r3c.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'friendlyarm_nanopi-r3c' targets/rockchip-armv8

