#!/bin/bash
#
# Ergaenzt die Unterstuetzung fuer das Mobilfunkgeraet ZTE MF286R.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-cellular.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Mobilfunk: ZTE MF286R"

apply_patch "$PATCH_DIR/cellular.patch" \
  "package/gluon-core/luasrc/lib/gluon/upgrade/250-cellular" \
  'zte,mf286r'
