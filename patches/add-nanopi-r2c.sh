#!/bin/bash
echo $PWD 

  echo "Applying patches for rockchip/nanopi-r2c"
  patchfile="../patches/add-nanopi-r2c.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'friendlyarm_nanopi-r2c' targets/rockchip-armv8

