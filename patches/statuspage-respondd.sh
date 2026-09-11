#!/bin/bash
#
# Stellt die Statusseite auf die Werte von neanderfunk-respondd um: Radios,
# Offline-SSID, Ethernet und Hardware, live ueber Gluons EventSource.
# Setzt auf statuspage-moredetails, -ssid, -hwdetails, -ethlinks und
# -ssidchanger-zaehler auf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-respondd.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: Werte aus neanderfunk-respondd, live"

apply_patch "$PATCH_DIR/statuspage-respondd.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'get_statistics'
