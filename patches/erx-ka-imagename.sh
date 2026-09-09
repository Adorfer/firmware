#!/bin/bash
#
# EdgeRouter X und X SFP bekommen unter Gluon 2025.1 einen eigenen Imagenamen:
# ubiquiti-edgerouter-x-ka bzw. ubiquiti-edgerouter-x-sfp-ka.
#
# Wird aus dem Gluon-Verzeichnis heraus aufgerufen, so wie prepare.sh es tut:
#   pushd ../gluon ; ../patches/erx-ka-imagename.sh ; popd
#
#
# Warum
# -----
# Der ERX wechselt mit Gluon 2025.1 das Flash-Layout (zwei Kernel-Slots zu je
# 3 MB -> ein Slot zu 6 MB). OpenWrt riegelt das ueber compat_version 1.0->2.0
# ab. Der Riegel sitzt aber an der denkbar teuersten Stelle:
#
#   1. Autoupdater findet seine Manifestzeile (model_ok)
#   2. newer_than() sagt neuer
#   3. PRIORITY=0 -> Probability 1, ab Tag 1 bei allen 24 Cronlaeufen
#   4. Image wird komplett geladen, SHA256 und Signatur sind korrekt
#   5. erst danach: sysupgrade --test -> fwtool_check_image()
#        if [ "${devicecompat%.*}" != "${imagecompat%.*}" ]; then return 1
#      Der major-Zweig wertet IGNORE_MINOR_COMPAT nicht aus; das
#      --ignore-minor-compat-version des Autoupdaters hilft hier nicht.
#   6. fail_after_download -> Mirror fliegt aus der Liste, naechster Mirror,
#      kompletter Zyklus von vorn. Wir fuehren vier Mirrors je Branch.
#
# Ein nicht migrierter ERX bleibt damit dauerhaft auf 2023.2, zieht dabei aber
# 24 * 4 * ~7,2 MB = rund 690 MB pro Tag durch den Tunnel und stoppt/startet
# 24-mal taeglich cron, urngd, micrond und sysntpd (download.d/abort.d).
# Sichtbar ist nichts davon: kein respondd-Feld, nichts auf der Statusseite,
# nur logread.
#
# Mit eigenem Imagenamen bricht derselbe Node schon bei model_ok ab - vor dem
# Download, fuer ein paar KB Manifest.
#
#
# Wie
# ---
# Zwei Stellen muessen synchron wandern:
#
#   A  DTS "model"  -> /tmp/sysinfo/model -> libplatforminfo sanitize_image_name()
#      -> platforminfo_get_image_name(), also das, was der Node meldet.
#      Fuer ramips gibt es keine eigene targets/*.c in libplatforminfo, es
#      greift default.c, und das liest "model", nicht "board_name".
#   B  erstes Argument von device() in targets/ramips-mt7621, also Manifestkey
#      und Dateiname.
#
# "compatible" bleibt unangetastet. SUPPORTED_DEVICES in der Imagedefinition
# kommt aus dem Profilnamen (SUPPORTED_DEVICES += ubnt-erx ubiquiti,edgerouterx),
# nicht aus "model" - fwtool_check_image() und platform_upgrade_ubnt_erx()
# merken von der Umbenennung also nichts. Der Migrationsweg selbst bleibt heil.
# "model" ist Identitaet, "compatible" ist Funktion.
#
# Kein manifest_aliases setzen. Ein Alias 'ubiquiti-edgerouter-x' am neuen
# Device wuerde den ganzen Effekt aufheben.
#
#
# Nebenwirkung, beabsichtigt
# --------------------------
# Der Name steht via respondd (software.firmware.image_name) auf der Karte und
# in der Model-Zeile der Statusseite. Ein ERX ohne "-ka" ist damit ein noch
# nicht migriertes Geraet, flottenweit filterbar.
#
#
# Wieder rausnehmen
# -----------------
# Sobald kein ERX ohne "-ka" mehr im Feld steht (Karte), in dieser Reihenfolge:
#
#   1. Rename zuruecknehmen (dieses Skript und seine beiden Patches raus) und
#      im selben Zug am wieder unbenannten Device
#         manifest_aliases = {'ubiquiti-edgerouter-x'}       -- bzw. -sfp
#      setzen, damit die Nodes, die noch "-ka" melden, ihre Manifestzeile
#      finden.
#   2. Einen Releasezyklus warten, bis alle auf dem unbenannten Image sind.
#   3. manifest_aliases wieder raus.
#
# Dafuer braucht es keinen Patch am Autoupdater; manifest_aliases ist der von
# Gluon vorgesehene Hebel - 2023.2 fuehrt dort aus demselben Grund 'ubnt-erx'.

. "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"

echo "ramips-mt7621: EdgeRouter X und X SFP auf Imagenamen -ka"

apply_patch "$PATCH_DIR/erx-ka-imagename-gluon.patch" \
  "targets/ramips-mt7621" \
  'ubiquiti-edgerouter-x-ka'

enter_dir openwrt

apply_patch "$PATCH_DIR/erx-ka-imagename-openwrt.patch" \
  "target/linux/ramips/dts/mt7621_ubnt_edgerouter-x.dts" \
  'EdgeRouter X KA'
