#!/bin/bash
#
# Begrenzt die WLAN-Puffer je nach RAM des Geraets (Backport von Gluon
# 8f38662f, siehe Kopf von limit-wireless-buffers.patch).
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/limit-wireless-buffers.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "WLAN-Puffer nach RAM begrenzen"

apply_patch "$PATCH_DIR/limit-wireless-buffers.patch" \
  "package/gluon-core/files/etc/hotplug.d/ieee80211/01-gluon-core-codel-memusage" \
  'memory_limit'
