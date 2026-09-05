#!/bin/bash
#
# Ergaenzt das Target ramips-mt7621 um den Totolink X5000R und legt den
# Kernel-Patch fuer dessen Zbit-ZB25VQ128-Flash im OpenWrt-Baum ab.
#
# Der Zbit-Patch ist an den Kernel 5.15 gebunden. Ab Kernel 6.6 wird er nicht
# mehr gebraucht (generischer SFDP-Rueckfall), siehe Kapitel 4.1 in
# docs/migration-2025.1-targets.md. Faellt das Verzeichnis patches-5.15 weg,
# bricht copy_into_tree hier hoerbar ab - genau so ist es gemeint.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-totolink-x5000r.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

ZBIT_PATCH="412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch"

echo "ramips-mt7621: Totolink X5000R"

apply_patch "$PATCH_DIR/add-totolink-x5000r.patch" \
  "targets/ramips-mt7621" \
  'totolink_x5000r'

enter_dir openwrt

copy_into_tree "$PATCH_DIR/$ZBIT_PATCH" \
  "target/linux/ramips/patches-5.15/$ZBIT_PATCH"
