#!/bin/bash
echo $PWD 

  echo "Applying patches for mediatek-filogic/Mercusys MR90X on gluon"
  patchfile="../patches/add-mercusys-mr90x-gluon.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep 'mercusys_mr90x-v1' targets/mediatek-filogic
