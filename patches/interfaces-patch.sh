#!/bin/bash
echo $PWD 
  echo "patching interfaces-macs 010 primary"
  patchfile="../patches/010-primary-mac.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi

  echo "patching interfaces 020"
  patchfile="../patches/020-interfaces.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi


