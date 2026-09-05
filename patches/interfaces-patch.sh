#!/bin/bash
#
# Passt die primaere MAC-Adresse und die Schnittstellenzuordnung fuer die
# Geraete an, die Gluon selbst nicht kennt.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/interfaces-patch.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Schnittstellen: primaere MACs und Zuordnung"

echo "- 010-primary-mac"
apply_patch "$PATCH_DIR/010-primary-mac.patch" \
  "package/gluon-core/luasrc/lib/gluon/upgrade/010-primary-mac" \
  'linksys,ea8300'

echo "- 020-interfaces"
apply_patch "$PATCH_DIR/020-interfaces.patch" \
  "package/gluon-core/luasrc/lib/gluon/upgrade/020-interfaces" \
  'avm,fritzbox-7530'
