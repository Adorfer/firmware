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

echo "Patches aus patches/ anwenden, Phase $PHASE ..."

if [ "$PHASE" = "pre-update" ]; then

  # Alle drei legen eine Datei im Gluon-Baum ab, die "make update" gleich
  # darauf auf ein Modul anwendet. Sie muessen deshalb hier stehen und nicht
  # unten.
  run_patch add-gluon-package-patches.sh  "Paketpatch fuer packages/gluon bereitlegen"
  run_patch add-lantiq-xrx200-devices.sh  "AVM FRITZ!Box 7430 und 3390, mit OpenWrt-Patch"
  run_patch add-ffac-package-patches.sh   "Paketpatch fuer packages/ffac bereitlegen"

  echo
  echo "Phase pre-update abgeschlossen."
  exit 0
fi

run_patch fix-respondd-rsk.sh          "respondd-Listener auf den Gluon-2016.x-Wert"
run_patch mi4apatch.sh                 "Mi Router 4A Gigabit sysupgrade-faehig"
run_patch add-totolink-x5000r.sh       "Totolink X5000R"
run_patch add-mercusys-mr90x.sh        "MERCUSYS MR90X"
run_patch add-dlink-m30.sh             "D-Link AQUILA PRO AI M30 A1"
run_patch fix-xiaomi-ax6s-bootflags.sh "Xiaomi Redmi AX6S: Boot-Flags bestaetigen (kein Rueckfall auf Stock)"
run_patch add-nanopi-r2c.sh            "FriendlyElec NanoPi R2C"
run_patch add-cudy-3000.sh             "Cudy-3000-Serie im Target mediatek-filogic"
run_patch additionaltargets.sh         "zusaetzliche Targets und Geraete aus OpenWrt"
run_patch add-cellular.sh              "Mobilfunkgeraet ZTE MF286R"
run_patch interface-role-migration21.sh "Migration 2021: Schnittstellen mit Client-Netz"
run_patch interfaces-patch.sh          "primaere MACs und Schnittstellenzuordnung"
run_patch patch-gluon-makefiles.sh     "Gluon-Makefile und Paketliste"
run_patch limit-wireless-buffers.sh    "WLAN-Puffer nach RAM begrenzen (Backport Gluon 8f38662f)"
run_patch revert-mips-tlb-uniquify.sh  "MIPS: r4k_tlb_uniquify() zuruecknehmen (Kaltstart-Haenger 74Kc)"

# Reihenfolge beachten: moredetails fuegt direkt hinter der Modellzeile ein,
# ssid und hwdetails setzen auf diesem Zustand auf.
run_patch statuspage-moredetails.sh    "Statusseite: weitere MACs und Gluon-Version"
run_patch statuspage-ssid.sh           "Statusseite: SSID, HT-Modus und ssid-changer"
run_patch statuspage-hwdetails.sh      "Statusseite: CPU-Typ, Kernzahl und BIOS"
run_patch statuspage-ethlinks.sh       "Statusseite: Ethernet-Geschwindigkeit je Port"
run_patch statuspage-ssidchanger-zaehler.sh "Statusseite: Zaehler des ssid-changer seit Boot"
run_patch statuspage-respondd.sh       "Statusseite: Werte aus neanderfunk-respondd, live"
run_patch web-static-version.sh        "Statusseite und Config-Mode: CSS/JS mit Versionsanhang"
run_patch wizard-save-only.sh          "Config-Mode: Wizard mit Speichern ohne Neustart, Warnung beim Verlassen"
run_patch wizard-save-lock.sh          "Config-Mode: nur ein Speichern & Neustarten gleichzeitig"
run_patch setup-mode-hostnames.sh      "Setup-Mode: gluon.setup und setup.gluon per DNS auf 192.168.1.1"
run_patch setup-mode-captive.sh        "Setup-Mode: Portal-Erkennung der Clients fuehrt auf die Setup-Seite"
run_patch setup-mode-wifi.sh           "Setup-Mode: WLAN-Zugang setup.gluon_<MAC> mit Umleitung auf die Setup-Seite"

run_patch outdoor-schalter.sh           "Outdoor-Schalter unabhaengig von preserve_channels"

run_patch state-check-shell.sh          "gluon-state-check als Shell statt Lua (RAM-Druck auf 64-MB-Geraeten)"

# Entfernt am 11.09.2026, weil sie nicht mehr aufgerufen wurden (die
# Geschichte steht in git):
#
# add-mt7915e-try.sh                   mt76-Korrekturen fuer MT7603/MT7612;
#                                      patches/mt7915e-try.patch war nie im Repo
# airtime-logsilience.sh               hielt den Airtime-Monitor aus dem Log,
#   + 999-silence-missing-rate.patch   Gluon bringt das inzwischen selbst mit
# ignore-preservechannels-for-outdoormode.sh (+ .patch.old)
#                                      Vorgaenger von outdoor-schalter.sh
#                                      (2020-2022, baute dazu 200-wireless um)
# tunneldiggergit.sh/.patch            git:// -> https:// fuer tunneldigger,
#                                      das Makefile im Feed hat laengst https
# targets-ipq40xx-mirotik.patch        Dublette mit Tippfehler zu -mikrotik
#
# git am ../patches/0001-*             frueher: durchnummerierte Patches
#                                      automatisch anwenden

echo
echo "Phase post-update abgeschlossen, alle Patches angewendet."
