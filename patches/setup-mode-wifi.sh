#!/bin/bash
#
# Setup-Mode per WLAN, Firmware-Anteil: dnsmasq des Setup-Modes an br-setup
# binden, Portal-Umleitung auf SERVER_ADDR. Das Setup-WLAN selbst liefert das
# Paket neanderfunk-setup-wifi. Setzt auf setup-mode-hostnames und
# setup-mode-captive auf. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Setup-Mode: dnsmasq an br-setup, Portal-Umleitung fuer neanderfunk-setup-wifi"

# Die fruehere Fassung dieses Patches legte S19wpad an. Der Gluon-Baum wird
# zwischen den Laeufen nicht bereinigt (build.sh, "git reset --hard" ohne
# "git clean"), die Datei bliebe also im Image - und neanderfunk-setup-wifi
# haelt sich heraus, solange sie da ist.
rm -f "package/gluon-setup-mode/files/lib/gluon/setup-mode/rc.d/S19wpad"

apply_patch "$PATCH_DIR/setup-mode-wifi.patch" \
  "package/gluon-setup-mode/files/lib/gluon/setup-mode/rc.d/S60dnsmasq" \
  'interface=br-setup'
