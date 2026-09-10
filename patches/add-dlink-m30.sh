#!/bin/bash
#
# Ergaenzt das Target mediatek-filogic um den D-Link AQUILA PRO AI M30 A1.
#
# OpenWrt 23.05 kennt das Geraet schon (seit 6e51ff88b0), es fehlt nur der
# Eintrag in Gluon. Dazu der Fix aus OpenWrt 24.10 d92fc99360: vor dem
# sysupgrade sw_tryactive auf 0 setzen, damit U-Boot sicher die
# OpenWrt-Partition startet; die bootpart-Logik in bootcount entfaellt.
#
# Kein recovery-Image: Gluon hat es in #3816 (47729c8517) entfernt, es
# installiert nicht. Installation: OpenWrt-Recovery (initramfs) ueber die
# D-Link-Recovery, danach das Gluon-sysupgrade-Image.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-dlink-m30.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-filogic: D-Link AQUILA PRO AI M30 A1"

apply_patch "$PATCH_DIR/add-dlink-m30-gluon.patch" \
  "targets/mediatek-filogic" \
  'dlink_aquila-pro-ai-m30-a1'

enter_dir openwrt

apply_patch "$PATCH_DIR/add-dlink-m30-openwrt.patch" \
  "target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" \
  'dlink,aquila-pro-ai-m30-a1)'
