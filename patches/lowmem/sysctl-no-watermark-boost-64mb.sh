#!/bin/bash
#
# base-files: vm.watermark_boost_factor=0 auf Geraeten mit 64 MB oder weniger.
# Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

echo "base-files: kein Watermark-Boost auf 64-MB-Geraeten"

enter_dir openwrt

apply_patch "$PATCH_DIR/sysctl-no-watermark-boost-64mb.patch" \
  "package/base-files/files/etc/init.d/sysctl" \
  'watermark_boost_factor=0'
