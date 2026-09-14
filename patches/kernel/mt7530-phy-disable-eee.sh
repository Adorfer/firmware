#!/bin/bash
#
# Kernel: EEE am MT7530-PHY (auch Switch des MT7621) abschalten und bei
# Bedarf neu aushandeln. Nachbau von OpenWrt PR #25058 fuer 5.15;
# Einzelheiten im Patchkopf.
#
# Legt den Patch nur ab: OpenWrt wendet target/linux/generic/hack-5.15/ beim
# Kernel-Bau selbst an (nach 766, vor den Target-Patches).
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/kernel/mt7530-phy-disable-eee.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

EEE_PATCH="767-net-phy-mediatek-ge-disable-EEE-on-MT7530-PHY.patch"

echo "Kernel: EEE am MT7530-PHY aus (MT7621-Switch)"

enter_dir openwrt

copy_into_tree "$PATCH_DIR/$EEE_PATCH" \
  "target/linux/generic/hack-5.15/$EEE_PATCH"
