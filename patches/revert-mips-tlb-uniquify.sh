#!/bin/bash
#
# Legt den Kernel-Patch ab, der r4k_tlb_uniquify() wieder aus der
# TLB-Initialisierung nimmt.
#
# Grund und Beleg stehen im Kopf der Patchdatei. Kurz: auf MIPS 74Kc bleibt
# der Kernel 5.15.198 beim Kaltstart in tlb_init() stehen. Warmstarts und
# sysupgrades ueberstehen die Geraete, der erste Stromausfall nicht.
#
# Der Patch liegt unter target/linux/generic/, nicht unter ath79: ramips-mt7621
# (MIPS 1004Kc) benutzt denselben Code, und dass er dort nicht zuschlaegt, ist
# nicht erwiesen - die mt7621-Knoten waren bisher nur nicht kaltgestartet.
#
# Post-update-Phase: "make update" setzt den OpenWrt-Baum neu auf und wuerde
# die Datei sonst wieder wegnehmen. OpenWrt wendet sie beim Kernel-Prepare
# selbst an, sie wird hier also nur hineinkopiert.
#
# Beim Umstieg auf Gluon 2025.1 neu bewerten: dort laeuft ein neuerer Kernel,
# in dem der Fehler behoben sein kann. Faellt hack-5.15 weg, bricht
# copy_into_tree hoerbar ab - genau so ist es gemeint.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/revert-mips-tlb-uniquify.sh ; popd

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

TLB_PATCH="999-mips-tlb-r4k-no-uniquify.patch"

echo "MIPS: r4k_tlb_uniquify() aus der TLB-Initialisierung nehmen"

enter_dir openwrt

copy_into_tree "$PATCH_DIR/$TLB_PATCH" \
  "target/linux/generic/hack-5.15/$TLB_PATCH"
