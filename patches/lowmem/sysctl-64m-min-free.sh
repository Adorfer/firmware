#!/bin/bash
#
# gluon-core: vm.min_free_kbytes=2048 und kleinere Fragmentpuffer auf
# Geraeten mit 64 MB RAM. Backport aus Gluon main (a505f767 + Fix c6ac8914,
# David Bauer); Einzelheiten im Patchkopf.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/lowmem/sysctl-64m-min-free.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/../lib-patch.sh"

echo "gluon-core: sysctl fuer 64-MB-Geraete (min_free_kbytes 2048)"

apply_patch "$PATCH_DIR/sysctl-64m-min-free.patch" \
  "package/gluon-core/luasrc/lib/gluon/upgrade/550-sysctl" \
  'memory-64m.conf'

# patch legt neue Dateien ohne Ausfuehrungsrecht an; Gluon uebernimmt die
# Rechte der Quelle, und ein Upgrade-Skript ohne x-Bit laeuft nicht.
chmod 755 package/gluon-core/luasrc/lib/gluon/upgrade/550-sysctl \
  || patch_abort "550-sysctl liess sich nicht ausfuehrbar machen."
