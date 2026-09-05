#!/bin/bash
#
# Ergaenzt das Target mediatek-filogic um den MERCUSYS MR90X.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-mercusys-mr90x.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-filogic: MERCUSYS MR90X"

apply_patch "$PATCH_DIR/add-mercusys-mr90x-gluon.patch" \
  "targets/mediatek-filogic" \
  'mercusys_mr90x-v1'
