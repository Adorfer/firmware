#!/bin/bash
#
# Ergaenzt das Target lantiq-xrx200 um die AVM FRITZ!Box 7430 und 3390.
#
# Laeuft in der Phase pre-update, weil derselbe Patch zugleich
# patches/openwrt/0008-lantiq-fix-ath9k-eeprom-for-AVM-Fritz-Box-7430.patch
# im Gluon-Baum ablegt. Diese Datei spielt "make update" ueber scripts/patch.sh
# auf den OpenWrt-Baum ein; nach "make update" abgelegt wuerde sie erst im
# naechsten Lauf wirken - und nur so lange, wie sie einen "git reset --hard"
# als unversionierte Datei ueberlebt.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-lantiq-xrx200-devices.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "lantiq-xrx200: AVM FRITZ!Box 7430 und 3390"

apply_patch "$PATCH_DIR/targets-lantiq-xrx200-devices.patch" \
  "targets/lantiq-xrx200" \
  'avm_fritz7430'

[ -f "patches/openwrt/0008-lantiq-fix-ath9k-eeprom-for-AVM-Fritz-Box-7430.patch" ] \
  || patch_abort "der OpenWrt-Patch fuer die FRITZ!Box 7430 liegt nicht in patches/openwrt/."
echo "  patches/openwrt/0008-lantiq-...patch liegt bereit fuer make update."
