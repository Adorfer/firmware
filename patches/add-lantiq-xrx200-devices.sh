#!/bin/bash
#
# Ergaenzt das Target lantiq-xrx200 um die AVM FRITZ!Box 3390.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-lantiq-xrx200-devices.sh ; popd
#
# Unter 2023.2 machte dieses Skript zwei Dinge mehr, beide sind unter 2025.1
# entfallen:
#
#   * Die FRITZ!Box 7430 fuehrt Gluon 2025.1 selbst (targets/lantiq-xrx200).
#     Unser device() legte sie ein zweites Mal an.
#   * Es legte patches/openwrt/0008-lantiq-fix-ath9k-eeprom-for-AVM-Fritz-Box-
#     7430.patch im Gluon-Baum ab, den "make update" per "git am" einspielt.
#     OpenWrt 24.10 hat den Fix selbst, und zwar anders geloest: der
#     avm,fritz7430-Zweig in
#     target/linux/lantiq/xrx200/base-files/etc/hotplug.d/firmware/12-ath9k-eeprom
#     ruft jetzt "fritz_cal_extract -r -i 4" auf. Das Werkzeug kann das
#     Umdrehen inzwischen selbst - genau das, was die Commit-Message unseres
#     Patches noch als fehlend nannte und per Shell nachbaute. Der Patch liess
#     sich folglich nicht mehr anwenden und brach "make update" ab.
#
# Damit bleibt nur die 3390, und das Skript legt keine Datei mehr im Gluon-Baum
# ab. Es laeuft deshalb in der Phase post-update, nicht mehr pre-update.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "lantiq-xrx200: AVM FRITZ!Box 3390"

apply_patch "$PATCH_DIR/targets-lantiq-xrx200-devices.patch" \
  "targets/lantiq-xrx200" \
  'avm_fritz3390'
