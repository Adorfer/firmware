#!/bin/bash
#
# Passt das Gluon-Makefile und die Paketliste an.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/patch-gluon-makefiles.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

WHISPERER_MAKEFILE="packages/community/ffda-node-whisperer/Makefile"
WHISPERER_HASH="2783a35814b5c638d208db4aa34897ee95a9fb5797e23c16ad1861b4967212a9"

echo "Gluon-Makefiles"

echo "- Makefile"
apply_patch "$PATCH_DIR/gluon-makefile.patch" \
  "Makefile" \
  'override GLUON_TARGETS'

echo "- Paket-Patches"
apply_patch "$PATCH_DIR/gluon-packages.patch" \
  "patches/packages/gluon/0001-delete-etc-opkg-keys-on-autoupdater-upgrade-does-trigger-on-autoupdate-after-checking-that-the-image-is-correct.patch"

# ffda-node-whisperer hat upstream keinen PKG_MIRROR_HASH, also uebergibt
# OpenWrt den Platzhalter --hash="x", verweigert den Download-Cache und klont
# bei jedem Bau neu. Mit dem Hash nutzt es dl/ffda-node-whisperer-1.tar.xz.
echo "- PKG_MIRROR_HASH fuer ffda-node-whisperer"
# Das Verzeichnis packages/ legt erst "make update" an; build.sh ruft
# prepare.sh deshalb danach auf.
[ -f "$WHISPERER_MAKEFILE" ] \
  || patch_abort "$WHISPERER_MAKEFILE nicht gefunden - lief 'make update' vorher?"
if grep -q PKG_MIRROR_HASH "$WHISPERER_MAKEFILE"; then
  echo "  $WHISPERER_MAKEFILE: bereits gesetzt."
else
  sed -i "/^PKG_SOURCE_VERSION:=/a PKG_MIRROR_HASH:=$WHISPERER_HASH" "$WHISPERER_MAKEFILE" \
    || patch_abort "sed auf $WHISPERER_MAKEFILE fehlgeschlagen."
  grep -q "PKG_MIRROR_HASH:=$WHISPERER_HASH" "$WHISPERER_MAKEFILE" \
    || patch_abort "sed lief durch, aber PKG_MIRROR_HASH steht nicht in $WHISPERER_MAKEFILE."
  echo "  $WHISPERER_MAKEFILE: gesetzt."
fi
