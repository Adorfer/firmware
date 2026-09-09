#!/bin/bash
#
# Laesst die Host-Werkzeuge von OpenWrt 23.05 mit heutigen Compilern
# uebersetzen.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/host-tools-gcc15.sh ; popd
#
# 23.05 ist gegen GCC 12/13 entstanden. Auf einem heutigen Host - hier GCC 15.2
# - bricht der Bau in "tools/install" ab, also lange vor dem eigentlichen
# Target. Betroffen ist bisher zweierlei:
#
#   squashfs3-lzma  Code von 2006. Seit GCC 14 ist
#                   -Wincompatible-pointer-types ein Fehler statt einer
#                   Warnung, und mksquashfs.c uebergibt an signal() einen
#                   Handler mit unpassender Signatur.
#
#                     mksquashfs.c:2060:33: error: passing argument 2 of
#                     'signal' from incompatible pointer type
#
#   elfutils 0.189  baut mit -Werror. GCC 15 bemaengelt im RISC-V-Disassembler
#                   ein verworfenes const:
#
#                     riscv_disasm.c:1259:46: error: initialization discards
#                     'const' qualifier from pointer target type
#                     [-Werror=discarded-qualifiers]
#
# Beide Male wird die Warnung abgeschaltet, nicht der Code korrigiert. Das sind
# Werkzeuge, die auf dem Bauhost laufen und Dateiformate erzeugen, die wir
# teilweise gar nicht verwenden - squashfs3 gehoert zu ath79-Geraeten, die
# ueberhaupt nur gebaut werden, weil die frisch erzeugte .config eines neuen
# Baums auf ath79 steht, bevor GLUON_TARGET greift. Sie muessen uebersetzen,
# nicht gut sein.
#
# Faellt vollstaendig weg, sobald wir 23.05 nicht mehr bauen. Unter 24.10
# stellt sich die Frage nicht.
#
# Kommt ein weiteres Werkzeug dazu, gehoert es hierher - nicht in ein eigenes
# Skript.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Host-Werkzeuge: Uebersetzung mit GCC 14+"

enter_dir openwrt

apply_patch "$PATCH_DIR/host-tools-gcc15-squashfs3.patch" \
  "tools/squashfs3-lzma/Makefile" \
  'Wno-incompatible-pointer-types'

apply_patch "$PATCH_DIR/host-tools-gcc15-elfutils.patch" \
  "tools/elfutils/Makefile" \
  'Wno-error'
