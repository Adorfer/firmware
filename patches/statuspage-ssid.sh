#!/bin/bash
#
# Ergaenzt die Gluon-Statusseite um SSID und HT-Modus je Radio.
# Backport aus Gluon v2025.1, siehe Kopf von statuspage-ssid.patch.
#
# Setzt auf dem Zustand nach statuspage-moredetails.sh auf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-ssid.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: SSID und HT-Modus je Radio"

apply_patch "$PATCH_DIR/statuspage-ssid.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'radio\.ssid'
