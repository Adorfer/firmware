#!/bin/bash
#
# ag71xx: kein BUG(), wenn der RX-Ring mangels Speicher leerlaeuft.
#
# Archer C25 v1 (64 MB, ath9k + ath10k) unter RAM-Druck: das Nachfuellen des
# RX-Rings scheitert, und sobald alle Deskriptoren verbraucht sind, loest
# ag71xx_assert(0) in ag71xx_rx_packets() eine Kernel-Panik aus (Befund der
# Paketfeed-Session, scratch/2026-09-12-c25-befund.md). Der Treiber hat fuer
# genau diesen Fall einen Rueckweg (oom_timer), die Assertion kommt ihm nur
# zuvor. Einzelheiten im Patchkopf.
#
# Der Treiber liegt unter target/linux/ath79/files/ und wird vor den Patches
# in den Kernelbaum kopiert; ein Kernel-Patch in patches-5.15/ greift also.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

KPATCH="950-ag71xx-rx-ring-exhausted-no-bug.patch"
TARGET="target/linux/ath79/patches-5.15/$KPATCH"

echo "ag71xx: kein BUG() bei leerem RX-Ring"

enter_dir openwrt

# Anders als copy_into_tree: eine vorhandene, aber veraltete Kopie (aus einem
# frueheren Lauf, unversioniert, ueberlebt git reset) wird ersetzt.
if [ -f "$TARGET" ] && cmp -s "$PATCH_DIR/$KPATCH" "$TARGET"; then
  echo "  $TARGET: liegt bereits im Baum."
else
  [ -d "$(dirname "$TARGET")" ] \
    || patch_abort "$(dirname "$TARGET") gibt es nicht - passt der Pfad noch zum Baum?"
  cp "$PATCH_DIR/$KPATCH" "$TARGET" || patch_abort "$KPATCH liess sich nicht kopieren."
  echo "  $TARGET: kopiert."
fi

# Der Patch muss auf den Treiber passen, sonst scheitert erst der Kernelbau.
# Probe gegen die Quelle unter files/ (dieselbe Datei, anderer Praefix).
DRV="target/linux/ath79/files"
( cd "$DRV" && patch -p1 -s -f --dry-run < "$PATCH_DIR/$KPATCH" >/dev/null ) \
  || patch_abort "$KPATCH passt nicht auf $DRV/drivers/net/ethernet/atheros/ag71xx/ag71xx_main.c."
