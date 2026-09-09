#!/bin/bash
#
# Laesst tools/squashfs3-lzma mit GCC 14 und neuer uebersetzen.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/squashfs3-lzma-gcc15.sh ; popd
#
# squashfs3-lzma ist Code von 2006. Seit GCC 14 ist
# -Wincompatible-pointer-types ein Fehler statt einer Warnung, und
# mksquashfs.c uebergibt an signal() einen Handler mit unpassender Signatur:
#
#   mksquashfs.c:2060:33: error: passing argument 2 of 'signal' from
#   incompatible pointer type [-Wincompatible-pointer-types]
#
# Der Bau bricht damit schon in "tools/install" ab, lange vor dem eigentlichen
# Target. Auf diesem Host ist GCC 15.2.
#
# Warum das ueberhaupt gebaut wird, obwohl wir ramips bauen: das Tool haengt in
# tools/Makefile an CONFIG_TARGET_ath79, und die frisch erzeugte .config eines
# neuen Baums steht auf ath79, bevor GLUON_TARGET greift. Ein frischer 23.05-
# Baum kommt deshalb ohne diesen Patch auf einem heutigen Host nicht durch.
#
# -Wno-incompatible-pointer-types statt einer Korrektur an mksquashfs.c: das
# Werkzeug erzeugt squashfs3-Images fuer ath79-Geraete, die wir nicht bauen. Es
# muss uebersetzen, nicht gut sein.
#
# Faellt weg, sobald wir 23.05 nicht mehr bauen. Unter 24.10 stellt sich die
# Frage nicht - dort ist das Tool ebenfalls an ath79 gebunden, aber der
# Kompilierfehler ist upstream behoben.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "tools/squashfs3-lzma: Uebersetzung mit GCC 14+"

enter_dir openwrt

apply_patch "$PATCH_DIR/squashfs3-lzma-gcc15-openwrt.patch" \
  "tools/squashfs3-lzma/Makefile" \
  'Wno-incompatible-pointer-types'
