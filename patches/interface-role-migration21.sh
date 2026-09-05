#!/bin/bash
#
# 2021er-Migration: Schnittstellen mit Client-Netz behalten ihre Rolle.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/interface-role-migration21.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Migration 2021: Schnittstellenrollen mit Client-Netz"

apply_patch "$PATCH_DIR/interface-role-migration21.patch" \
  "package/gluon-core/luasrc/lib/gluon/upgrade/021-interface-roles" \
  'client or client'
