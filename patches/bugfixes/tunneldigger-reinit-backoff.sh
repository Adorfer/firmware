#!/bin/bash
#
# tunneldigger-Client: Reinit mit wirksamer Pause, kein ioctl auf ein
# fehlendes mesh-vpn.
#
# Knoten mit Mesh-VPN an, aber ohne WAN (Mesh nur ueber LAN/WLAN): der Client
# dreht ohne Pause Reinit -> DNS scheitert -> Reinit, und jeder Reinit fragt
# per ioctl nach mesh-vpn. Der Kernel startet dafuer zweimal modprobe
# (netdev-mesh-vpn, mesh-vpn). Am WDR3600 115 modprobe in 30 s, Load 1,5,
# CPU 0 % idle; am Archer C25 jedes Mal vom Flash. Einzelheiten im Kopf von
# 100-tunneldigger-reinit-backoff-no-modprobe.patch.
#
# Das Paket kommt aus dem Modul packages (freifunk-gluon/packages) und hat
# selbst kein patches/-Verzeichnis. Die Quellpatch-Datei muss also als neue
# Datei net/tunneldigger/patches/<name> ins Modul. Das geht nur ueber Gluons
# Modulpatches: dieses Skript baut daraus einen Patch fuer "git am" und legt
# ihn unter patches/packages/packages/ im Gluon-Baum ab, "make update" spielt
# ihn ein (scripts/patch.sh). Deshalb Phase pre-update. Direkt ins Modul
# kopiert wuerde die Datei beim naechsten Lauf von "git clean" entfernt.
#
# Die Quellpatch-Datei gibt es nur einmal, hier in patches/; der Modulpatch
# wird bei jedem Lauf daraus erzeugt. Zieht der Feed tunneldigger auf einen
# anderen Stand, scheitert der Paketbau laut am Patch - dann hier anpassen.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

SRC_PATCH="100-tunneldigger-reinit-backoff-no-modprobe.patch"
PKG_FILE="net/tunneldigger/patches/$SRC_PATCH"
MODULE_DIR="patches/packages/packages"
TARGET="$MODULE_DIR/0100-tunneldigger-reinit-backoff-no-modprobe.patch"

echo "tunneldigger: Reinit mit Pause, kein modprobe fuer mesh-vpn (Modulpatch)"

[ -f "$PATCH_DIR/$SRC_PATCH" ] || patch_abort "$SRC_PATCH fehlt in patches/."
[ -d "$MODULE_DIR" ] \
  || patch_abort "$MODULE_DIR gibt es nicht - legt Gluon seine Modulpatches noch dort ab?"

# Das Datum steht fest, damit der erzeugte Patch von Lauf zu Lauf gleich
# bleibt (Vergleich unten, golden-Fingerabdruck).
LINES="$(wc -l < "$PATCH_DIR/$SRC_PATCH")"
TMP="$(mktemp)"
{
  echo "From: Freifunk im Neanderland <projekt@neanderfunk.de>"
  echo "Date: Sat, 12 Sep 2026 21:30:00 +0200"
  echo "Subject: tunneldigger: reinit back-off that waits, no modprobe for a missing mesh-vpn"
  echo
  echo "Adds $PKG_FILE; the reasoning is in the header of that patch."
  echo
  echo "diff --git a/$PKG_FILE b/$PKG_FILE"
  echo "new file mode 100644"
  echo "--- /dev/null"
  echo "+++ b/$PKG_FILE"
  echo "@@ -0,0 +1,$LINES @@"
  sed 's/^/+/' "$PATCH_DIR/$SRC_PATCH"
} > "$TMP"

# Wie ag71xx: eine vorhandene, aber veraltete Kopie (unversioniert, ueberlebt
# git reset) wird ersetzt.
if [ -f "$TARGET" ] && cmp -s "$TMP" "$TARGET"; then
  echo "  $TARGET: liegt bereits im Baum."
  rm -f "$TMP"
else
  mv "$TMP" "$TARGET" || patch_abort "$TARGET liess sich nicht anlegen."
  chmod 644 "$TARGET"
  echo "  $TARGET: angelegt."
fi
