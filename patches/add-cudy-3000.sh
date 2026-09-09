#!/bin/bash
#
# Ergaenzt das Target mediatek-filogic um Cudy AP3000 v1 und TR3000 256MB v1.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/add-cudy-3000.sh ; popd
#
#
# Unter 2023.2 brachte dieses Skript die ganze Cudy-3000-Serie mit, in vier
# Teilen. Drei davon sind unter 2025.1 upstream angekommen:
#
#   * add-cudy-3000-openwrt.patch legte acht DTS, die Imagedefinitionen in
#     filogic.mk und den Cudy-Zweig in 11_fix_wifi_mac an. OpenWrt 24.10 hat
#     alle acht DTS, zwoelf Cudy-Geraete in filogic.mk und denselben
#     11_fix_wifi_mac-Zweig als Obermenge (zusaetzlich wr3000p-v1).
#   * add-cudy-3000-singleeth-openwrt.patch trug vier Geraete in
#     05_set_preinit_iface ein. Alle vier stehen dort upstream, in denselben
#     Zweigen.
#   * 486-02-...-F50L1G41LC (ESMT-Flash) - siehe Kommentar unten in der
#     Historie, 24.10 bringt den Chip selbst mit.
#
# Auch auf der Gluon-Seite fuehrt v2025.1.3 die Serie inzwischen selbst. Unser
# alter Patch legte acht device() an, davon fuenf doppelt (m3000, tr3000,
# wr3000e, wr3000h, wr3000s). Uebrig bleiben zwei, die upstream fehlen:
#
#   cudy-ap3000-v1          model "Cudy AP3000 v1"
#   cudy-tr3000-256mb-v1    model "Cudy TR3000 256MB v1"
#
# ACHTUNG beim Rueckportieren: unser 2023.2-Patch nennt das Outdoor-Geraet
# 'cudy-ap3000outdoor-v1', die DTS aber "Cudy AP3000 Outdoor v1". Daraus macht
# libplatforminfo 'cudy-ap3000-outdoor-v1', und der Knoten findet seine
# Manifestzeile nicht. Upstream schreibt es richtig, deshalb steht das Geraet
# hier nicht mehr in unserem Patch. Auf v2023.2.x ist der Fehler offen.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "mediatek-filogic: Cudy AP3000 v1 und TR3000 256MB v1"

apply_patch "$PATCH_DIR/add-cudy-3000-gluon.patch" \
  "targets/mediatek-filogic" \
  'cudy_ap3000-v1'
