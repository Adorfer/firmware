#!/bin/bash
#
# Xiaomi Redmi AX6S: legt die Flags des A/B-Bootloaders auf das OpenWrt-Image fest,
# damit er nicht nach einigen Neustarts auf die Stock-Firmware zurueckfaellt.
# Einzelheiten im Kopf von fix-xiaomi-ax6s-bootflags.patch.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-mt7622: Xiaomi Redmi AX6S, Boot-Flags bestaetigen"

enter_dir openwrt
apply_patch "$PATCH_DIR/fix-xiaomi-ax6s-bootflags.patch" \
  "target/linux/mediatek/mt7622/base-files/etc/init.d/bootcount" \
  'xiaomi_ab_pin_openwrt'
