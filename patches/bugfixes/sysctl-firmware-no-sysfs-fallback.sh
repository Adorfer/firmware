#!/bin/bash
#
# base-files: kernel.firmware_config.ignore_sysfs_fallback=1 fuer alle
# Targets. Fehlende Firmware (z. B. tg3_tso5.bin am FUTRO) haelt sonst den
# Boot bis zu 60 s unter RTNL an. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

echo "base-files: kein sysfs-Fallback fuer fehlende Firmware"

enter_dir openwrt
apply_patch "$PATCH_DIR/sysctl-firmware-no-sysfs-fallback.patch" \
  "package/base-files/files/etc/sysctl.d/12-firmware-no-sysfs-fallback.conf" \
  'ignore_sysfs_fallback=1'
