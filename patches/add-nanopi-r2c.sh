#!/bin/bash
#
# Ergaenzt das Target rockchip-armv8 um den FriendlyElec NanoPi R2C.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-nanopi-r2c.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "rockchip-armv8: FriendlyElec NanoPi R2C"

apply_patch "$PATCH_DIR/add-nanopi-r2c.patch" \
  "targets/rockchip-armv8" \
  'friendlyarm_nanopi-r2c'
