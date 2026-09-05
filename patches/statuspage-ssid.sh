#!/bin/bash
#
# Ergaenzt die Gluon-Statusseite um SSID und HT-Modus je Radio.
# Backport aus Gluon v2025.1, siehe Kopf von statuspage-ssid.patch.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/statuspage-ssid.sh ; popd

set -o nounset
set -o pipefail

PATCH_FILE="../patches/statuspage-ssid.patch"
TARGET_FILE="package/gluon-status-page/files/lib/gluon/status-page/view/status-page.html"

echo "Gluon-Statuspage: SSID und HT-Modus je Radio"

# Alle Pfade gequotet. Ein unquotetes "<$patchfile" ist genau die Falle, an der
# hier schon mehrere Patch-Skripte still gescheitert sind: ein Leerzeichen im
# Pfad ergibt "ambiguous redirect", und das Kommando laeuft gar nicht erst.
if [ ! -f "$PATCH_FILE" ]; then
  echo "  FEHLER: $PATCH_FILE nicht gefunden." >&2
  exit 1
fi

if [ ! -f "$TARGET_FILE" ]; then
  echo "  FEHLER: $TARGET_FILE nicht gefunden - laeuft das Skript im Gluon-Verzeichnis?" >&2
  exit 1
fi

# Laesst sich der Patch rueckwaerts anwenden, ist er bereits drin. prepare.sh
# laeuft je Lauf mehrfach, das Skript muss also idempotent sein.
if patch -R -p1 -s -f --dry-run --ignore-whitespace <"$PATCH_FILE" >/dev/null 2>&1; then
  echo "  bereits angewendet, nichts zu tun."
  exit 0
fi

# -f, damit patch bei unerwartetem Zustand abbricht statt interaktiv zu fragen
# und den Build haengen zu lassen.
if ! patch -p1 -f --ignore-whitespace <"$PATCH_FILE"; then
  echo "  FEHLER: Patch liess sich nicht anwenden." >&2
  exit 1
fi

# Ergebnis pruefen statt nur ausgeben: ein durchgelaufener patch-Aufruf allein
# ist noch kein Beleg, dass die Aenderung auch drin steht.
if ! grep -q 'radio\.ssid' "$TARGET_FILE"; then
  echo "  FEHLER: Patch lief durch, aber die SSID-Ausgabe fehlt in $TARGET_FILE." >&2
  exit 1
fi

echo "  ok: SSID- und htmode-Ausgabe sind in $TARGET_FILE."
