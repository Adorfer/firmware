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
