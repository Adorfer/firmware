#!/bin/bash
#
# tunneldigger-watchdog als Shell-Skript statt Lua: auf 64-MB-Geraeten kam
# die Lua-Laufzeit alle 5 Minuten vom Flash. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "tunneldigger-watchdog: Shell statt Lua"

# Ohne Merkmal, aus demselben Grund wie in state-check-shell.sh: nach
# "git reset --hard" darf keine Lua-Fassung ueber der Shell-Fassung landen.
apply_patch "$PATCH_DIR/tunneldigger-watchdog-shell.patch" \
  "package/gluon-mesh-vpn-tunneldigger/files/usr/bin/tunneldigger-watchdog"

[ ! -e "package/gluon-mesh-vpn-tunneldigger/luasrc/usr/bin/tunneldigger-watchdog" ] \
  || patch_abort "Die Lua-Fassung von tunneldigger-watchdog ist noch da."

# patch legt neue Dateien ohne Ausfuehrungsrecht an; micrond startet das
# Skript direkt.
chmod 755 "package/gluon-mesh-vpn-tunneldigger/files/usr/bin/tunneldigger-watchdog"
