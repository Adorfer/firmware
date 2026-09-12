#!/bin/bash
#
# Setup-Mode: dnsmasq loest gluon.setup und setup.gluon auf 192.168.1.1 auf,
# alles andere bekommt REFUSED. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Setup-Mode: Hostnamen gluon.setup und setup.gluon"

apply_patch "$PATCH_DIR/setup-mode-hostnames.patch" \
  "package/gluon-setup-mode/files/lib/gluon/setup-mode/rc.d/S60dnsmasq" \
  'SETUP_MODE_HOSTNAMES='
