#!/bin/bash
#
# Ergaenzt die Gluon-Statusseite um CPU-Modell, BIOS und RAM/Flash.
# Siehe Kopf von statuspage-hwdetails.patch.
#
# Setzt auf dem Zustand nach statuspage-moredetails.sh auf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-hwdetails.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Statuspage: CPU-Modell, BIOS und RAM/Flash"

apply_patch "$PATCH_DIR/statuspage-hwdetails.patch" \
  "package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html" \
  'get_cpu_model'
