#!/bin/bash
echo $PWD 

  echo "Gluon-Statuspage: Adding infos (more MAC, gluonversion)"
  patchfile="../patches/statuspage-moredetails.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "Version in statuspage?: ";grep 'Gluon Version' package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html
