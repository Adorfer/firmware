#!/bin/bash
#
# Statusseite: Offline-SSID-Zeile als x/y/z mit den Zaehlern des
# neanderfunk-ssid-changer seit Boot - siehe Kopf des Patches.
#
# Setzt auf dem Ende der Statusseiten-Kette auf (moredetails, ssid,
# hwdetails, ethlinks).
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-ssidchanger-zaehler.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: Zaehler des ssid-changer seit Boot"

apply_patch "$PATCH_DIR/statuspage-ssidchanger-zaehler.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'get_ssid_changer_counts'
