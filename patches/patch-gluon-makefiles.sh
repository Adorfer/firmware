#!/bin/bash
echo $PWD 
  echo "patching glunon-makefile"
  patchfile="../patches/gluon-makefile.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "patching gluon-packages"
  patchfile="../patches/gluon-packages.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  # ffda-node-whisperer has no PKG_MIRROR_HASH upstream, so OpenWrt passes the
  # placeholder --hash="x", refuses the download cache and does a full git clone
  # on every single build. With the hash it uses dl/ffda-node-whisperer-1.tar.xz.
  echo "adding PKG_MIRROR_HASH to ffda-node-whisperer"
  grep -q PKG_MIRROR_HASH packages/community/ffda-node-whisperer/Makefile || sed -i '/^PKG_SOURCE_VERSION:=/a PKG_MIRROR_HASH:=2783a35814b5c638d208db4aa34897ee95a9fb5797e23c16ad1861b4967212a9' packages/community/ffda-node-whisperer/Makefile


