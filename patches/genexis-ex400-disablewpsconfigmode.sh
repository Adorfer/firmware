#!/bin/bash
echo $PWD 

  echo "Applying patch for NoWPS-Touchbutton for ramips-mt7621/genexis-ex400"
  patchfile="../patches/genexis-ex400-disablewpsconfigmode.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  echo -n "patch in target?: ";grep -A1 'genexis-pulse-ex400' package/gluon-setup-mode/files/etc/hotplug.d/button/50-gluon-setup-mode
