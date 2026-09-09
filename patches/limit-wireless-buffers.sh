#!/bin/bash
#
# Deckelt die WLAN-Puffer auch oberhalb von 128 MB RAM auf 2 MB.
#
# Unter 2023.2 war das ein vollstaendiger Backport von Gluon 8f38662f. Der
# Commit ist Vorfahr von v2025.1.3; uebrig bleibt allein unsere Abweichung von
# upstream. Begruendung im Kopf von limit-wireless-buffers.patch.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/limit-wireless-buffers.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

CODEL="package/gluon-core/files/etc/hotplug.d/ieee80211/01-gluon-core-codel-memusage"

echo "WLAN-Puffer auch oberhalb 128 MB RAM deckeln"

# Kein check_pattern an apply_patch: das frueher benutzte 'memory_limit' steht
# seit 8f38662f im unveraenderten Baum und wuerde den Patch stillschweigend
# ueberspringen, sobald der Vorwaerts-Test einmal fehlschlaegt.
apply_patch "$PATCH_DIR/limit-wireless-buffers.patch"

# Merkmal ist die Abwesenheit der oberen Staffel: nach unserem Patch gibt es
# keine 128-MB-Schwelle mehr, sondern ein else.
if grep -q '128\*1024' "$CODEL"; then
  patch_abort "$CODEL traegt weiterhin die 128-MB-Schwelle - der Patch hat nicht gegriffen."
fi
echo "  $CODEL: obere Staffel entfernt."
