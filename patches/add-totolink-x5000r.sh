#!/bin/bash
#
# Ergaenzt das Target ramips-mt7621 um den Totolink X5000R.
#
# Unter 2023.2 legte dieses Skript zusaetzlich
# 412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch in
# target/linux/ramips/patches-5.15/ ab. Das Verzeichnis gibt es unter Kernel
# 6.6 nicht mehr, und der Patch wird auch nicht mehr gebraucht: ab 6.6 greift
# der generische SFDP-Rueckfall (Kapitel 4.1 in
# docs/migration-2025.1-targets.md). Die Patchdatei bleibt als Beleg liegen,
# eingespielt wird sie nicht mehr.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-totolink-x5000r.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "ramips-mt7621: Totolink X5000R"

apply_patch "$PATCH_DIR/add-totolink-x5000r.patch" \
  "targets/ramips-mt7621" \
  'totolink_x5000r'
