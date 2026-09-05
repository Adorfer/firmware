#!/bin/bash
#
# Ergaenzt die Gluon-Statusseite um weitere MAC-Adressen und die Gluon-Version.
#
# Reihenfolge beachten: statuspage-ssid.sh und statuspage-hwdetails.sh setzen
# auf dem Zustand nach diesem Patch auf und muessen danach laufen.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-moredetails.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: weitere MACs und Gluon-Version"

apply_patch "$PATCH_DIR/statuspage-moredetails.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'Gluon Version'
