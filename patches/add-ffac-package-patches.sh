#!/bin/bash
#
# Legt den Paketpatch ab, den Gluon auf das Modul packages/ffac anwendet.
#
# Der Patch macht aus ffac-mt7915-maxinactivity eine Entscheidung je Radio:
# das Paket wird nach Build-Target eingebaut, und auf ramips/mt7621 steckt
# genauso oft mt7603/mt76x2 wie mt7915. Auf einem Xiaomi Mi Router 4A Gigabit
# stand deshalb max_inactivity=10 auf zwei Radios, die von openwrt/mt76#1009
# gar nicht betroffen sind. Siehe patches/ffac-packages.patch.
#
# Laeuft in der Phase pre-update, aus demselben Grund wie
# add-gluon-package-patches.sh: die Datei landet unter patches/packages/ffac
# im Gluon-Baum, und "make update" spielt sie ueber scripts/patch.sh per
# "git am" auf das Modul ein. Nach "make update" abgelegt wuerde sie erst im
# naechsten Lauf wirken.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-ffac-package-patches.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "ffac-Paketpatches fuer make update bereitlegen"

apply_patch "$PATCH_DIR/ffac-packages.patch" \
  "patches/packages/ffac/0001-mt7915-maxinactivity-decide-per-radio-not-per-build-target.patch"
