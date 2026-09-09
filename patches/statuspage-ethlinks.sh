#!/bin/bash
#
# Zeigt auf der Statusseite je Ethernet-Port die ausgehandelte Geschwindigkeit
# und markiert, was auffaellig ist.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-ethlinks.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: Ethernet-Geschwindigkeit je Port"

apply_patch "$PATCH_DIR/statuspage-ethlinks.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'get_ethlinks'
