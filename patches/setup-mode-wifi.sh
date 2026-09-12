#!/bin/bash
#
# Setup-Mode per WLAN: eigenes AP (setup.gluon_<MAC>) in eigener Bridge mit
# DNS-Catch-all und Umleitung auf die Setup-Seite. Setzt auf
# setup-mode-hostnames und setup-mode-captive auf. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Setup-Mode: WLAN-Zugang setup.gluon_<MAC>"

apply_patch "$PATCH_DIR/setup-mode-wifi.patch" \
  "package/gluon-setup-mode/files/lib/gluon/setup-mode/rc.d/S20network" \
  'SETUP_WIFI_ADDR='

# patch legt neue Dateien ohne Ausfuehrungsrecht an; rc.common-Skripte muessen
# ausfuehrbar sein. Gluon kopiert files/ mit "cp -fpR".
chmod 755 "package/gluon-setup-mode/files/lib/gluon/setup-mode/rc.d/S19wpad"
