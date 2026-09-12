#!/bin/bash
#
# Config-Mode-Wizard: nur ein "Speichern & Neustarten" gleichzeitig (Sperre
# gegen ueberlappende gluon-reconfigure-Laeufe). Setzt auf wizard-save-only
# auf. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Config-Mode: nur ein Speichern & Neustarten gleichzeitig"

apply_patch "$PATCH_DIR/wizard-save-lock.patch" \
  "package/gluon-config-mode-core/luasrc/lib/gluon/config-mode/model/gluon-config-mode/wizard.lua" \
  'wizard-save.done\|/var/gluon/setup-mode/wizard-save'
