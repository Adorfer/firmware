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

# Cudys AX3000-Serie traegt ab Seriennummer 2543 (Produktion ab November 2025)
# den Flash ESMT F50L1G41LC. Der nutzt eine andere Hersteller-ID (0x8c) als der
# bisherige F50L1G41LB (0xc8) und wird von Kernel 5.15 deshalb gar nicht
# erkannt - das Geraet bootet dann nicht, unabhaengig vom Image. Upstream ist
# der Chip erst ab 24.10 dabei (backport-6.6/422-v6.19-...), hier
# rueckportiert.
#
# Liegt in generic/pending-5.15, weil der Chip nicht an ein Target gebunden
# ist. Setzt 486-01 voraus, der esmt.c ueberhaupt erst anlegt - faellt das
# Verzeichnis unter einem neueren Kernel weg, bricht copy_into_tree ab.
LC_PATCH="486-02-mtd-spinand-esmt-add-support-for-F50L1G41LC.patch"

copy_into_tree "$PATCH_DIR/$LC_PATCH" \
  "target/linux/generic/pending-5.15/$LC_PATCH"
