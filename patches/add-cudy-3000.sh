#!/bin/bash
#
# Ergaenzt die Cudy-3000-Serie: das Target mediatek-filogic in Gluon, die
# Imagedefinitionen und die Preinit-Schnittstelle in OpenWrt.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-cudy-3000.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-filogic: Cudy-3000-Serie"

apply_patch "$PATCH_DIR/add-cudy-3000-gluon.patch" \
  "targets/mediatek-filogic" \
  'wr3000e'

enter_dir openwrt

apply_patch "$PATCH_DIR/add-cudy-3000-openwrt.patch" \
  "target/linux/mediatek/image/filogic.mk" \
  'wr3000e'

# AP3000 Outdoor hat nur einen Ethernet-Anschluss; ohne den Patch sucht der
# Preinit die falsche Schnittstelle.
apply_patch "$PATCH_DIR/add-cudy-3000-singleeth-openwrt.patch" \
  "target/linux/mediatek/base-files/lib/preinit/05_set_preinit_iface" \
  'cudy,ap3000-v1'

# Unter 2023.2 legte dieses Skript hier zusaetzlich
# 486-02-mtd-spinand-esmt-add-support-for-F50L1G41LC.patch in
# target/linux/generic/pending-5.15/ ab, fuer den ESMT F50L1G41LC in Cudys
# AX3000-Serie ab Seriennummer 2543. OpenWrt 24.10 bringt den Chip selbst mit
# (backport-6.6/422-v6.19-...), das Verzeichnis pending-5.15 gibt es nicht
# mehr. Die Patchdatei bleibt als Beleg liegen, eingespielt wird sie nicht
# mehr.
