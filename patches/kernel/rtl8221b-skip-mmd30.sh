#!/bin/bash
#
# Kernel: beim Suchen nach C45-PHYs MMD 30 des RTL8221B nicht lesen. Das
# Lesen legt den PHY lahm, sobald er einen Link hat (Kabel beim Booten
# gesteckt), bis zum Hardware-Reset. Backport aus OpenWrt 88dcd8c303b6 nach
# 5.15; Einzelheiten im Patchkopf.
#
# Legt den Patch nur ab: OpenWrt wendet target/linux/generic/hack-5.15/ beim
# Kernel-Bau selbst an.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/kernel/rtl8221b-skip-mmd30.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

MMD30_PATCH="791-net-phy-skip-MMD-30-for-RTL8221B-when-reading-C45-PH.patch"

echo "Kernel: MMD 30 des RTL8221B beim PHY-Scan auslassen"

enter_dir openwrt

copy_into_tree "$PATCH_DIR/$MMD30_PATCH" \
  "target/linux/generic/hack-5.15/$MMD30_PATCH"
