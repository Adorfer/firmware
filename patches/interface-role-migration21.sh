#!/bin/bash
echo $PWD 
patchfile="../patches/interface-role-migration21.patch"
if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
  patch -p1 --ignore-whitespace <$patchfile
fi
grep 'client or client'  package/gluon-core/luasrc/lib/gluon/upgrade/021-interface-roles
