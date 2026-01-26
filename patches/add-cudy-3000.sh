#!/bin/bash
echo $PWD 

  echo "Applying patches for mediatek-filogic/cudy-3000 series on gluon"
  patchfile="../patches/add-cudy-3000-gluon.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 -f --ignore-whitespace <$patchfile
   fi
  grep 'wr3000e' targets/mediatek-filogic

  cd openwrt 
  patchfile="../../patches/add-cudy-3000-openwrt.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 -f --ignore-whitespace <$patchfile
   fi
  grep  'wr3000e' target/linux/mediatek/image/filogic.mk

  patchfile="../../patches/patches/add-cudy-3000-singleeth-openwrt.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 -f --ignore-whitespace <$patchfile
   fi
  grep  'cudy,ap3000-v1' target/linux/mediatek/base-files/lib/preinit/05_set_preinit_iface
  
  popd
