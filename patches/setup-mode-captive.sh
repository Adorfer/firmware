#!/bin/bash
#
# Setup-Mode: Die Portal-Erkennung der Clients (Probe-Hosts per DNS, 404 per
# uhttpd -E) fuehrt auf die Setup-Seite. Setzt auf setup-mode-hostnames auf.
# Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Setup-Mode: Portal-Erkennung fuehrt auf die Setup-Seite"

apply_patch "$PATCH_DIR/setup-mode-captive.patch" \
  "package/gluon-config-mode-core/files/lib/gluon/setup-mode/rc.d/S50uhttpd" \
  '/cgi-bin/portal'

# patch legt neue Dateien ohne Ausfuehrungsrecht an; uhttpd startet ein CGI
# nur, wenn es ausfuehrbar ist. Gluon kopiert files/ mit "cp -fpR", das Recht
# kommt also ins Image.
chmod 755 "package/gluon-config-mode-core/files/lib/gluon/config-mode/www/cgi-bin/portal"
