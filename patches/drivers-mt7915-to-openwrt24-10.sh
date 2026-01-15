#!/bin/bash
echo $PWD 

  echo "Applying drivers mt7915 filogic to openwrt24-10 with ple patch"
  [ -f patches/openwrt/0013-mt7915-detect-and-purge-stuck-PLE-queues.patch ] && echo "patches/openwrt/0013-mt7915-detect-and-purge-stuck-PLE-queues.patch exists, skipping copy." || cp ../patches/0013-mt7915-detect-and-purge-stuck-PLE-queues.patch patches/openwrt/0013-mt7915-detect-and-purge-stuck-PLE-queues.patch 

  pushd openwrt
  patchfile="../../patches/drivers-mt7915-to-openwrt24-10.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'PKG_SOURCE_DATE:=2025-11-06' package/kernel/mt76/Makefile
  popd