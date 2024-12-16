#!/bin/bash
echo $PWD 

  echo "Applying patches for ramips-mt7621/Totolink-X5000R on gluon"
  patchfile="../patches/add-totolink-x5000r.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'totolink_x5000r' targets/ramips-mt7621
  pushd openwrt
  [ -f target/linux/ramips/patches-5.10/412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch ] && echo "target/linux/ramips/patches-5.10/412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch exists, skipping copy." || cp ../../412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch target/linux/ramips/patches-5.10/412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch
  popd