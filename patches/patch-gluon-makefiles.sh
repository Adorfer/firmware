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


