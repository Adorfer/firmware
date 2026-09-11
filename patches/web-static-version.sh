#!/bin/bash
#
# Statusseite und Config-Mode laden CSS/JS mit ?v=<Release>, damit Browser
# nach einem Firmware-Update nicht die alten Dateien aus dem Cache nehmen.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Statusseite und Config-Mode: CSS/JS mit Versionsanhang"

apply_patch "$PATCH_DIR/web-static-version.patch" \
  "package/gluon-config-mode-theme/files/lib/gluon/config-mode/view/theme/layout.html" \
  'gluon.css?v='
