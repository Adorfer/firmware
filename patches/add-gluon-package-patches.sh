#!/bin/bash
#
# Legt die Paketpatches ab, die Gluon selbst auf das Modul packages/gluon
# anwendet:
#   0001  loescht /etc/opkg/keys beim Autoupdater-Upgrade
#   0100  respondd-module-airtime: busy/rx/tx groesser als active weglassen
#         (mt76 meldet untergelaufene Survey-Zaehler, die Karte zeigt sonst
#         Kanalauslastung weit ueber 100 %); Begruendung im Patchkopf
#
# Laeuft in der Phase pre-update: die Datei landet unter patches/packages/gluon
# im Gluon-Baum, und "make update" spielt sie ueber scripts/patch.sh per
# "git am" auf das Modul ein. Nach "make update" abgelegt wuerde sie erst im
# naechsten Lauf wirken.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-gluon-package-patches.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Gluon-Paketpatches fuer make update bereitlegen"

apply_patch "$PATCH_DIR/gluon-packages.patch" \
  "patches/packages/gluon/0001-delete-etc-opkg-keys-on-autoupdater-upgrade-does-trigger-on-autoupdate-after-checking-that-the-image-is-correct.patch"

# 0100 liegt als fertiger git-am-Patch in patches/. Wie bei ag71xx: eine
# vorhandene, aber veraltete Kopie (unversioniert, ueberlebt git reset) wird
# ersetzt.
AIRTIME_SRC="$PATCH_DIR/gluon-packages-airtime-plausible.patch"
AIRTIME_DST="patches/packages/gluon/0100-respondd-module-airtime-leave-out-busy-rx-tx-larger-than-active.patch"
[ -f "$AIRTIME_SRC" ] || patch_abort "$AIRTIME_SRC fehlt."
if [ -f "$AIRTIME_DST" ] && cmp -s "$AIRTIME_SRC" "$AIRTIME_DST"; then
  echo "  $AIRTIME_DST: liegt bereits im Baum."
else
  cp "$AIRTIME_SRC" "$AIRTIME_DST" || patch_abort "$AIRTIME_DST liess sich nicht anlegen."
  echo "  $AIRTIME_DST: kopiert."
fi
