#!/bin/bash
#
# Legt den Paketpatch ab, den Gluon auf das Modul packages/packages anwendet -
# den OpenWrt-Paketfeed.
#
# Inhalt: das Host-Perl von OpenWrt 23.05 ist 5.28.1 und uebersetzt nicht mehr
# mit einem heutigen Compiler. Seit GCC 14 ist -Wincompatible-pointer-types ein
# Fehler statt einer Warnung, und SDBM_File.xs uebergibt an Perl_safesysfree
# einen SDBM_File:
#
#   SDBM_File.xs:72:22: error: passing argument 1 of 'Perl_safesysfree' from
#   incompatible pointer type [-Wincompatible-pointer-types]
#
# "Configure -der" leitet seine ccflags selbst ab, der Schalter muss deshalb
# ueber -Accflags hinein. Betrifft nur das Host-Perl; das Perl fuers Geraet
# wird ueber files/perlconfig.pl konfiguriert und ist unberuehrt.
#
# Laeuft in der Phase pre-update, aus demselben Grund wie
# add-gluon-package-patches.sh: die Datei landet unter
# patches/packages/packages im Gluon-Baum, und "make update" spielt sie ueber
# scripts/patch.sh per "git am" auf das Modul ein. Nach "make update" abgelegt
# wuerde sie erst im naechsten Lauf wirken.
#
# Faellt weg, sobald wir 23.05 nicht mehr bauen - 24.10 bringt ein neueres
# Perl mit. Verwandt: patches/host-tools-gcc15.sh, dieselbe Ursache bei
# squashfs3-lzma und elfutils.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-openwrt-package-patches.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "OpenWrt-Paketpatches fuer make update bereitlegen"

apply_patch "$PATCH_DIR/openwrt-packages-perl.patch" \
  "patches/packages/packages/0001-perl-host-build-with-GCC-14-and-later.patch"
