#!/bin/bash
#
# Macht den Xiaomi Mi Router 4A Gigabit per sysupgrade aktualisierbar: der
# Patch lockert die fwtool-Kompatibilitaetspruefung fuer dieses Geraet.
# Patchziel ist der OpenWrt-Baum, nicht Gluon.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/mi4apatch.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "OpenWrt: Mi Router 4A Gigabit sysupgrade-faehig machen"

enter_dir openwrt

apply_patch "$PATCH_DIR/mi4ag-migration.patch" \
  "package/base-files/files/lib/upgrade/fwtool.sh" \
  'xiaomi,mi-router-4a-gigabit'
