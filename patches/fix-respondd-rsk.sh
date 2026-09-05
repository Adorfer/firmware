#!/bin/bash
#
# Setzt die respondd-Listener-Adresse auf den Wert von Gluon 2016.x zurueck.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/fix-respondd-rsk.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "respondd: Listener-Adresse auf den Gluon-2016.x-Wert"

apply_patch "$PATCH_DIR/fix-respondd-rsk.patch" \
  "package/gluon-respondd/files/etc/init.d/gluon-respondd" \
  'ff02::1'
