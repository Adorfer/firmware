#!/bin/bash
echo $PWD 
  echo "removing 6M-Flash TP-Link-Devices"
  patchfile="../patches/targets-ath79-generic.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding Miktorik RB951ui2nd"
  patchfile="../patches/targets-ath79-mikrotik.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding ZTE MF281"
  patchfile="../patches/targets-ath79-nand.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding RPI4"
  patchfile="../patches/targets-ath79-nand.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding Linksys EA8300 MR8300"
  patchfile="../patches/targets-ipq40xx-generic.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding AVM FB7430"
  patchfile="../patches/targets-ipq40xx-generic.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding Edimax BR6478acv2"
  patchfile="../patches/targets-ramips-mt7620.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "adding Mikrotik RB750gr"
  patchfile="../patches/targets-ramips-mt7621.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "removing TP-Link re305 6MB flash"
  patchfile="../patches/targets-ramips-mt76x8.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi


