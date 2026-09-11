#!/bin/bash
#
# Wendet die Patches aus patches/ auf den Gluon-Baum an.
#
# Aufgerufen wird die Datei von build.sh (prepare_gluon_tree), je Lauf zweimal
# und mit dem Gluon-Verzeichnis als Arbeitsverzeichnis. Sie liegt als Kopie in
# jedem zusammengebauten Site-Verzeichnis, deshalb der Umweg ueber ../gluon.
#
# Zwei Phasen, weil "make update" dazwischen liegt:
#
#   prepare.sh pre-update    vor  "make update"
#   prepare.sh post-update   nach "make update"
#
# In die pre-update-Phase gehoert alles, was eine Datei unter patches/openwrt
# oder patches/packages im Gluon-Baum ablegt: Gluons scripts/patch.sh spielt
# diese Dateien waehrend "make update" per "git am" auf die Module ein. Danach
# abgelegt wuerden sie erst im naechsten Lauf wirken - und nur so lange, wie
# sie einen "git reset --hard" als unversionierte Dateien ueberleben.
#
# Alles andere gehoert in die post-update-Phase, insbesondere jeder Patch am
# OpenWrt-Baum: "make update" setzt den neu auf und wuerde die Aenderungen
# sonst wieder wegnehmen.
#
# Bis hierher endete die Datei mit "exit 0;", und keines der Patch-Skripte gab
# einen Fehler weiter. Ein scheiternder Patch fiel damit nicht auf - er ergab
# still eine Firmware, in der Geraete fehlen. Der Bau bricht jetzt an der
# ersten fehlgeschlagenen Stelle ab. Deshalb steht am Ende kein "exit 0;" mehr:
# der Rueckgabewert soll der der Patches sein.

set -o nounset
set -o errexit
set -o pipefail

# Vom Gluon-Verzeichnis aus gesehen ist das wieder es selbst; der Pfad bleibt
# so, damit die Skripte ihre Patches unveraendert unter ../patches finden.
GLUON_DIR="../gluon"

abort ()
{
  echo "prepare.sh: $*" >&2
  exit 1
}

PHASE="${1-}"
case "$PHASE" in
  pre-update|post-update) ;;
  *) abort "Aufruf: prepare.sh pre-update|post-update" ;;
esac

[ -d "$GLUON_DIR/package/gluon-core" ] \
  || abort "$GLUON_DIR ist kein Gluon-Baum - laeuft prepare.sh im Gluon-Verzeichnis? (Arbeitsverzeichnis: $PWD)"
[ -d "$GLUON_DIR/../patches" ] \
  || abort "$GLUON_DIR/../patches nicht gefunden."

# run_patch <skript> <beschreibung>
#
# Ruft das Skript im Gluon-Verzeichnis auf, in einer Subshell, damit ein cd
# darin (etwa nach openwrt) das naechste Skript nicht betrifft. Frueher stand
# hier pushd/popd; scheiterte das pushd, lief der Patch im falschen
# Verzeichnis, und das popd danach ebenfalls ins Leere.
run_patch ()
{
  local script="$1"
  local description="$2"

  echo
  echo "=== $script: $description"

  [ -x "$GLUON_DIR/../patches/$script" ] \
    || abort "patches/$script fehlt oder ist nicht ausfuehrbar."

  ( cd "$GLUON_DIR" && "../patches/$script" ) \
    || abort "patches/$script fehlgeschlagen ($description)."
}

# Liegengebliebene .rej und .orig aus frueheren Laeufen wegraeumen, bevor
# irgendetwas gepatcht wird.
#
# lib-patch.sh raeumt sie nur fuer die Patches auf, die es gleich anwendet.
# Faellt ein Patch weg - weil er unter 2025.1 redundant geworden ist - bleibt
# sein Rest fuer immer liegen: "git reset --hard" fasst unversionierte Dateien
# nicht an. Und Gluon kopiert package/*/files/. und luasrc/. vollstaendig ins
# Image, also landet so ein Rest in der Firmware.
#
# Aufgefallen an interface-role-migration21: dessen 021-interface-roles.rej
# blieb liegen, nachdem der Patch entfernt war. luasrcdiet versuchte, die
# Ablehnungsdatei als Lua zu minifizieren, und gluon-core liess sich nicht
# mehr bauen ("unexpected symbol near '+'").
sweep_patch_leftovers ()
{
  local leftover
  local -i count=0

  # Kein "-delete": das schaltet implizit -depth ein, womit -prune wirkungslos
  # wird und der Lauf durch das ganze build_dir liefe.
  while IFS= read -r leftover; do
    [ -n "$leftover" ] || continue
    if (( count == 0 )); then
      echo "  Liegengebliebene .rej/.orig aus frueheren Laeufen werden entfernt:"
    fi
    echo "    $leftover"
    rm -f "$leftover"
    count+=1
  done < <( find "$GLUON_DIR" -path "$GLUON_DIR/openwrt/build_dir" -prune -o \
                              -type f \( -name '*.rej' -o -name '*.orig' \) -print 2>/dev/null )
}

echo "Patches aus patches/ anwenden, Phase $PHASE ..."
sweep_patch_leftovers

if [ "$PHASE" = "pre-update" ]; then

  # Alle drei legen eine Datei im Gluon-Baum ab, die "make update" gleich
  # darauf auf ein Modul anwendet. Sie muessen deshalb hier stehen und nicht
  # unten.
  run_patch add-gluon-package-patches.sh  "Paketpatch fuer packages/gluon bereitlegen"
  run_patch add-ffac-package-patches.sh   "Paketpatch fuer packages/ffac bereitlegen"

  echo
  echo "Phase pre-update abgeschlossen."
  exit 0
fi

run_patch fix-respondd-rsk.sh          "respondd-Listener auf den Gluon-2016.x-Wert"
run_patch mi4apatch.sh                 "Mi Router 4A Gigabit sysupgrade-faehig"
run_patch add-totolink-x5000r.sh       "Totolink X5000R"
run_patch add-mercusys-mr90x.sh        "MERCUSYS MR90X"
run_patch add-nanopi-r2c.sh            "FriendlyElec NanoPi R2C"
run_patch add-lantiq-xrx200-devices.sh  "AVM FRITZ!Box 3390"
run_patch add-cudy-3000.sh             "Cudy-3000-Serie im Target mediatek-filogic"
run_patch remove-dlink-m30-recovery.sh "D-Link M30 ohne recovery-Image (Gluon #3816)"
run_patch fix-xiaomi-ax6s-bootflags.sh "Xiaomi Redmi AX6S: Boot-Flags bestaetigen (kein Rueckfall auf Stock)"
run_patch additionaltargets.sh         "zusaetzliche Targets und Geraete aus OpenWrt"
run_patch erx-ka-imagename.sh          "EdgeRouter X: eigener Imagename -ka (Flash-Layout)"
run_patch add-cellular.sh              "Mobilfunkgeraet ZTE MF286R"
run_patch interfaces-patch.sh          "primaere MACs und Schnittstellenzuordnung"
run_patch patch-gluon-makefiles.sh     "Gluon-Makefile und Paketliste"
run_patch limit-wireless-buffers.sh    "WLAN-Puffer oberhalb 128 MB RAM deckeln"

# Reihenfolge beachten: moredetails fuegt direkt hinter der Modellzeile ein,
# ssid und hwdetails setzen auf diesem Zustand auf.
run_patch statuspage-moredetails.sh    "Statusseite: ImageName, Mesh-MAC und Sitecode"
run_patch statuspage-ssid.sh           "Statusseite: Zustand des ssid-changer"
run_patch statuspage-hwdetails.sh      "Statusseite: CPU-Modell, BIOS und RAM/Flash"
run_patch statuspage-ethlinks.sh       "Statusseite: Ethernet-Geschwindigkeit je Port"
run_patch statuspage-ssidchanger-zaehler.sh "Statusseite: Zaehler des ssid-changer seit Boot"

run_patch outdoor-schalter.sh           "Outdoor-Schalter unabhaengig von preserve_channels"

# Deaktiviert, aber absichtlich dokumentiert:
#
# add-mt7915e-try.sh                   mt76-Korrekturen fuer MT7603/MT7612;
#                                      patches/mt7915e-try.patch war nie im Repo
# airtime-logsilience.sh               haelt den Airtime-Monitor aus dem Log
# ignore-preservechannels-for-outdoormode.sh  Vorgaenger von outdoor-schalter.sh
#                                      (2020-2022, baute dazu 200-wireless um)
#
# git am ../patches/0001-*             frueher: durchnummerierte Patches
#                                      automatisch anwenden

echo
echo "Phase post-update abgeschlossen, alle Patches angewendet."
