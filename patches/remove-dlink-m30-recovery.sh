#!/bin/bash
#
# Nimmt beim D-Link AQUILA PRO AI M30 A1 das recovery-Image heraus.
#
# Es installiert nicht: nach dem Einspielen ueber die D-Link-Recovery startet
# das Geraet neu und ist nicht mehr erreichbar (Berichte FFRN, FFMUC, FFAC,
# August 2026). Gluon hat es auf main entfernt (#3816, 47729c8517) und den
# Backport nach v2025.1.x vorgeschlagen - main und v2025.1.x binden dasselbe
# OpenWrt ein, in 2025.1 ist also nichts repariert, es fehlt nur der Nachzug.
#
# Installation stattdessen: das Recovery-Image von OpenWrt (initramfs) ueber
# die D-Link-Recovery, danach das Gluon-sysupgrade-Image.
#
# Uebernimmt Gluon die Entfernung spaeter selbst, erkennt apply_patch das an
# der Rueckwaertspruefung und ueberspringt den Patch.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/remove-dlink-m30-recovery.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-filogic: D-Link M30 ohne recovery-Image"

apply_patch "$PATCH_DIR/remove-dlink-m30-recovery.patch"
