#!/bin/bash
#
# Wendet die Patches aus patches/ auf den Gluon-Baum an.
#
# Aufgerufen wird die Datei von build.sh (prepare_gluon_tree), einmal je Lauf
# und mit dem Gluon-Verzeichnis als Arbeitsverzeichnis. Sie liegt als Kopie in
# jedem zusammengebauten Site-Verzeichnis, deshalb der Umweg ueber ../gluon.
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

echo "Patches aus patches/ anwenden ..."

run_patch fix-respondd-rsk.sh          "respondd-Listener auf den Gluon-2016.x-Wert"
run_patch mi4apatch.sh                 "Mi Router 4A Gigabit sysupgrade-faehig"
run_patch add-totolink-x5000r.sh       "Totolink X5000R"
run_patch add-mercusys-mr90x.sh        "MERCUSYS MR90X"
run_patch add-nanopi-r2c.sh            "FriendlyElec NanoPi R2C"
run_patch add-cudy-3000.sh             "Cudy-3000-Serie im Target mediatek-filogic"
run_patch additionaltargets.sh         "zusaetzliche Targets und Geraete aus OpenWrt"
run_patch add-cellular.sh              "Mobilfunkgeraet ZTE MF286R"
run_patch interface-role-migration21.sh "Migration 2021: Schnittstellen mit Client-Netz"
run_patch interfaces-patch.sh          "primaere MACs und Schnittstellenzuordnung"
run_patch patch-gluon-makefiles.sh     "Gluon-Makefile und Paketliste"

# Reihenfolge beachten: moredetails fuegt direkt hinter der Modellzeile ein,
# ssid und hwdetails setzen auf diesem Zustand auf.
run_patch statuspage-moredetails.sh    "Statusseite: weitere MACs und Gluon-Version"
run_patch statuspage-ssid.sh           "Statusseite: SSID und HT-Modus je Radio"
run_patch statuspage-hwdetails.sh      "Statusseite: CPU-Typ, Kernzahl und BIOS"

# Deaktiviert, aber absichtlich dokumentiert:
#
# add-mt7915e-try.sh                   mt76-Korrekturen fuer MT7603/MT7612;
#                                      patches/mt7915e-try.patch war nie im Repo
# mt7915-filogic-syncpowersave-patch.sh  patches/openwrt/0013-wifi-mt76-...
# airtime-logsilience.sh               haelt den Airtime-Monitor aus dem Log
# ignore-preservechannels-for-outdoormode.sh  Auto-Channel fuer Outdoor-Geraete
#
# git am ../patches/0001-*             frueher: durchnummerierte Patches
#                                      automatisch anwenden

echo
echo "Alle Patches angewendet."
