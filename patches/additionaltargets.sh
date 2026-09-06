#!/bin/bash
#
# Ergaenzt die Gluon-Targetdateien um Geraete, die Gluon selbst nicht fuehrt,
# und um zwei zusaetzliche Targets.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/additionaltargets.sh ; popd
#
# Welcher Patch beim Sprung auf Gluon 2025.1 entfaellt und welcher bleibt,
# steht in docs/migration-2025.1-targets.md, Kapitel 3.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "Zusaetzliche Targets und Geraete"

# Die alte Ueberschrift lautete "removing 6M-Flash TP-Link-Devices" - der Patch
# entfernt aber nichts, er ergaenzt EAP225 Wall v2 und Zyxel NBG6616. Nebenbei
# legt er ein zweites, gleichlautendes device() fuer den EAP225 Outdoor v3 an,
# den Gluon selbst schon fuehrt; das ist ueberfluessig und gehoert aufgeraeumt.
# Merkmal ist deshalb zyxel_nbg6616: eap225-outdoor-v3 steht auch im
# unveraenderten Baum und taugt nicht zur Unterscheidung.
echo "- TP-Link EAP225 Wall v2 und Zyxel NBG6616"
apply_patch "$PATCH_DIR/targets-ath79-generic.patch" \
  "targets/ath79-generic" \
  'zyxel_nbg6616'

echo "- Mikrotik RB951Ui-2nD"
apply_patch "$PATCH_DIR/targets-ath79-mikrotik.patch" \
  "targets/ath79-mikrotik" \
  'mikrotik_routerboard-mapl-2nd'

echo "- ZTE MF286R"
apply_patch "$PATCH_DIR/targets-ath79-nand.patch" \
  "targets/ath79-nand" \
  'zte_mf286r'

# Der zweite Aufruf stand hier unter der Ueberschrift "adding RPI4", nimmt aber
# dieselbe Patchdatei wie der ZTE MF286R darueber: einen RPI4-Patch gibt es
# nicht. Der Aufruf bleibt als Beleg stehen, er ist wirkungslos.
echo "- (RPI4: kein eigener Patch vorhanden, siehe Kommentar)"
apply_patch "$PATCH_DIR/targets-ath79-nand.patch" \
  "targets/ath79-nand" \
  'zte_mf286r'

echo "- Linksys EA8300 / MR8300"
apply_patch "$PATCH_DIR/targets-ipq40xx-generic.patch" \
  "targets/ipq40xx-generic" \
  'ATH10K_PACKAGES_IPQ40XX_QCA9984'

echo "- Targets ipq40xx-chromium und ipq807x-generic"
apply_patch "$PATCH_DIR/targets-mk.patch" \
  "targets/targets.mk" \
  'GluonTarget,ipq807x,generic'

echo "- Google Wifi"
apply_patch "$PATCH_DIR/targets-ipq40xx-chromium.patch" \
  "targets/ipq40xx-chromium" \
  'ATH10K_PACKAGES_IPQ40XX'

echo "- Mikrotik wAP G-5HacT2HnD / wAP ac"
apply_patch "$PATCH_DIR/targets-ipq40xx-mikrotik.patch" \
  "targets/ipq40xx-mikrotik" \
  'kmod-ath10k-smallbuffers'

echo "- Xiaomi AX3600, Netgear WAX218"
apply_patch "$PATCH_DIR/targets-ipq807x-generic.patch" \
  "targets/ipq807x-generic" \
  'ATH10K_PACKAGES_IPQ807X'

echo "- Unifi 6LR v2/v3, Netgear WAX206"
apply_patch "$PATCH_DIR/targets-mediatek-mt7622.patch" \
  "targets/mediatek-mt7622" \
  'ubnt_unifi-6-lr-v2'

# Auch dieser Aufruf stand unter einer fremden Ueberschrift ("adding AVM
# FB7430") und wiederholt nur den Linksys-Patch von oben. Die FB7430 kommt mit
# dem lantiq-Patch direkt darunter.
echo "- (AVM FB7430: der Aufruf darueber wiederholt nur ipq40xx-generic)"
apply_patch "$PATCH_DIR/targets-ipq40xx-generic.patch" \
  "targets/ipq40xx-generic" \
  'ATH10K_PACKAGES_IPQ40XX_QCA9984'

# AVM FRITZ!Box 7430 und 3390 stehen nicht mehr hier, sondern in
# add-lantiq-xrx200-devices.sh: derselbe Patch legt einen OpenWrt-Patch im
# Gluon-Baum ab und muss deshalb vor "make update" laufen.

# echo "- Edimax BR6478ACv2"
# apply_patch "$PATCH_DIR/targets-ramips-mt7620.patch" \
#   "targets/ramips-mt7620" \
#   'edimax_br-6478ac-v2'

echo "- Cudy M1800 und X6 v1, TP-Link Archer AX23 v1"
apply_patch "$PATCH_DIR/targets-ramips-mt7621.patch" \
  "targets/ramips-mt7621" \
  'cudy_m1800'
