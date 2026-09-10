#!/bin/bash
#
# Outdoor-Schalter in den Erweiterten Einstellungen und im Wizard unabhaengig
# von preserve_channels - siehe Kopf von outdoor-schalter.patch.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/outdoor-schalter.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon: Outdoor-Schalter unabhaengig von preserve_channels"

apply_patch "$PATCH_DIR/outdoor-schalter.patch" \
  "package/gluon-web-wifi-config/luasrc/lib/gluon/config-mode/model/admin/wifi-config.lua" \
  'Outdoor-Schalter haengt nur an der Hardware'
