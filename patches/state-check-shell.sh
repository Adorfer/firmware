#!/bin/bash
#
# gluon-state-check als Shell-Skript statt Lua: auf 64-MB-Geraeten kam die
# Lua-Laufzeit jede Minute vom Flash. Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "gluon-state-check: Shell statt Lua"

# Ohne Merkmal: nach "git reset --hard" ist die Lua-Datei zurueck, die neue
# Shell-Datei aber noch da (unversioniert). Ein Merkmal in der Shell-Datei
# hielte das faelschlich fuer angewendet, und im Image ueberschriebe luasrc/
# die Shell-Fassung. So raeumt apply_patch die Neuanlage weg und patcht neu.
apply_patch "$PATCH_DIR/state-check-shell.patch" \
  "package/gluon-state-check/files/usr/sbin/gluon-state-check"

[ ! -e "package/gluon-state-check/luasrc/usr/sbin/gluon-state-check" ] \
  || patch_abort "Die Lua-Fassung von gluon-state-check ist noch da."

# patch legt neue Dateien ohne Ausfuehrungsrecht an; micrond startet das
# Skript direkt. Gluon kopiert files/ mit "cp -fpR", das Recht kommt also
# ins Image.
chmod 755 "package/gluon-state-check/files/usr/sbin/gluon-state-check"
