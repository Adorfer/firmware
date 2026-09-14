#!/bin/bash
#
# squashfs-Blockgroesse je Geraet (OpenWrt include/image.mk) und die
# Zuordnung fuer ath79.
#
# OpenWrt kennt die Blockgroesse nur je Target. Der Patch fuehrt
# DEVICE_SQUASHFS_BLOCKSIZE ein, vorbelegt aus SQUASHFS_BLOCKSIZE/<geraet>,
# und macht die Blockgroesse zum Teil der Rootfs-ID. Einzelheiten im Patchkopf.
# Welche Geraete welche Blockgroesse bekommen, steht in
# squashfs-blocksize-ath79.mk; ohne aktive Zeile aendert sich an den Images
# nichts.
#
# Phase post-update (OpenWrt-Baum). Stand 13.09.2026: vorbereitet, noch nicht
# in prepare.sh eingetragen. Einschalten:
#   1. in templates/common/prepare.sh bei den OpenWrt-Patches
#      run_patch squashfs-blocksize-per-device.sh "squashfs-Blockgroesse je Geraet (ath79)"
#   2. in squashfs-blocksize-ath79.mk die gewuenschten Geraete entkommentieren
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

MAP_SRC="$PATCH_DIR/squashfs-blocksize-ath79.mk"
MAP_DST="target/linux/ath79/image/squashfs-blocksize.mk"

echo "squashfs-Blockgroesse je Geraet (ath79)"

enter_dir openwrt

apply_patch "$PATCH_DIR/openwrt-squashfs-blocksize-per-device.patch" \
  "include/image.mk" 'DEVICE_SQUASHFS_BLOCKSIZE'

# Wie ag71xx: eine vorhandene, aber veraltete Kopie (unversioniert, ueberlebt
# git reset) wird ersetzt.
[ -f "$MAP_SRC" ] || patch_abort "$MAP_SRC fehlt."
[ -d "$(dirname "$MAP_DST")" ] || patch_abort "$(dirname "$MAP_DST") gibt es nicht."
if [ -f "$MAP_DST" ] && cmp -s "$MAP_SRC" "$MAP_DST"; then
  echo "  $MAP_DST: liegt bereits im Baum."
else
  cp "$MAP_SRC" "$MAP_DST" || patch_abort "$MAP_DST liess sich nicht anlegen."
  echo "  $MAP_DST: kopiert."
fi
