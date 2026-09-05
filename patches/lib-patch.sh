# shellcheck shell=bash
#
# Gemeinsame Hilfsfunktionen fuer die Patch-Skripte in patches/.
#
# Eingebunden wird sie ueber den eigenen Skriptpfad, damit sie unabhaengig vom
# Arbeitsverzeichnis gefunden wird:
#
#   . "$(dirname "${BASH_SOURCE[0]}")/lib-patch.sh"
#
# Zweck ist die Fehlererkennung. Frueher liefen alle Patch-Skripte nach dem
# Muster "wenn der Rueckwaerts-Trockenlauf fehlschlaegt, patche vorwaerts" und
# werteten das Ergebnis nirgends aus; prepare.sh endete zusaetzlich mit
# "exit 0;". Ein scheiternder Patch fiel damit nicht auf - er ergab still eine
# Firmware, in der Geraete fehlen. Jeder Fehler bricht jetzt ab.
#
# Aufrufkontext: die Skripte laufen im Gluon-Verzeichnis (prepare.sh ruft sie
# von dort als ../patches/<name>.sh auf), einige wechseln danach nach openwrt.
# Alle Pfade sind gequotet: ein unquotetes "<$patchfile" ergibt bei einem
# Leerzeichen im Pfad "ambiguous redirect", und das Kommando laeuft dann gar
# nicht erst - genau daran sind hier schon Patches still gescheitert.

set -o nounset
set -o errexit
set -o pipefail

# Absoluter Pfad des patches/-Verzeichnisses, damit die Skripte ihre
# Patchdateien auch nach einem "cd openwrt" noch finden.
PATCH_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

patch_abort ()
{
  echo "  FEHLER: $*" >&2
  exit 1
}

# remove_patch_leftovers <patchdatei>
#
# Loescht .orig- und .rej-Dateien neben den Dateien, die der Patch anfasst.
#
# patch legt bei jedem Hunk-Versatz eine .orig-Kopie an. Die landet in der
# Firmware: Gluon kopiert package/*/files/. und luasrc/. vollstaendig ins Image
# (Gluon/Build/Install in package/gluon.mk). Ausgeliefert wurde dadurch unter
# anderem /lib/gluon/upgrade/020-interfaces.orig - ausfuehrbar, und
# gluon-reconfigure arbeitet das Verzeichnis mit "for script in *" ab. Die
# ungepatchte Fassung lief also direkt nach der gepatchten und ueberschrieb
# deren Schnittstellenzuordnung wieder.
#
# Neue .orig-Dateien verhindert --no-backup-if-mismatch. Die schon
# vorhandenen muessen weg: "git reset --hard" fasst unversionierte Dateien
# nicht an, sie ueberleben also jeden Lauf.
remove_patch_leftovers ()
{
  local patch_file="$1"
  local target

  # Aus den "+++ b/<pfad>"-Zeilen die Zieldateien ziehen (-p1, also b/ weg).
  while read -r target; do
    [ -n "$target" ] || continue
    [ "$target" = "/dev/null" ] && continue
    rm -f "$target.orig" "$target.rej"
  done < <(awk '/^\+\+\+ /{ sub(/^\+\+\+ [ab]\//, "", $0); sub(/[ \t].*$/, "", $0); print }' "$patch_file")
}

# remove_created_files <patchdatei>
#
# Loescht die Dateien, die der Patch neu anlegen wuerde ("--- /dev/null"),
# sofern sie schon da sind.
#
# Aufgerufen nur, wenn der Rueckwaerts-Test fehlgeschlagen ist, der Patch also
# nicht vollstaendig drinsteht. Dann sind vorhandene Neuanlagen Reste eines
# frueheren Laufs, den ein "git reset --hard" nur halb zurueckgenommen hat: es
# stellt versionierte Dateien wieder her, unversionierte laesst es stehen.
# patch scheitert an so einem Halbzustand mit "the next patch would create the
# file ..., which already exists".
remove_created_files ()
{
  local patch_file="$1"
  local target

  while read -r target; do
    [ -n "$target" ] || continue
    [ -e "$target" ] || continue
    echo "  $target: Rest eines frueheren Laufs, wird vor dem Patchen entfernt."
    rm -f "$target"
  done < <(awk '
    /^--- \/dev\/null/ {
      if ((getline line) > 0 && line ~ /^\+\+\+ /) {
        sub(/^\+\+\+ [ab]\//, "", line)
        sub(/[ \t].*$/, "", line)
        print line
      }
    }' "$patch_file")
}

# apply_patch <patchdatei> [pruefdatei] [pruefmuster]
#
# Wendet die Patchdatei relativ zum aktuellen Verzeichnis an (-p1). Ist sie
# bereits angewendet, passiert nichts. Sind Pruefdatei und -muster angegeben,
# wird hinterher geprueft, dass die Aenderung tatsaechlich im Baum steht: ein
# durchgelaufener patch-Aufruf allein ist dafuer noch kein Beleg.
apply_patch ()
{
  local patch_file="$1"
  local check_file="${2-}"
  local check_pattern="${3-}"

  [ -f "$patch_file" ] || patch_abort "$patch_file nicht gefunden (Arbeitsverzeichnis: $PWD)."

  remove_patch_leftovers "$patch_file"

  # Laesst sich der Patch rueckwaerts anwenden, ist er schon drin. prepare.sh
  # laeuft je Bau mehrfach, die Skripte muessen also idempotent sein.
  if patch -R -p1 -s -f --dry-run --ignore-whitespace <"$patch_file" >/dev/null 2>&1; then
    echo "  $patch_file: bereits angewendet."
  elif [ -n "$check_file" ] && [ -n "$check_pattern" ] && [ -f "$check_file" ] \
       && grep -q "$check_pattern" "$check_file"; then
    # Der Rueckwaerts-Test scheitert auch dann, wenn ein spaeterer Patch
    # dieselbe Stelle noch einmal veraendert hat: statuspage-ssid und
    # statuspage-hwdetails setzen genau so auf statuspage-moredetails auf.
    # Steht das Merkmal schon im Baum, ist trotzdem nichts zu tun.
    echo "  $patch_file: '$check_pattern' steht bereits in $check_file, nichts zu tun."
    return 0
  else
    remove_created_files "$patch_file"

    # -f, damit patch bei unerwartetem Zustand abbricht, statt interaktiv zu
    # fragen und den Build haengen zu lassen.
    # --no-backup-if-mismatch: ohne das legt patch bei jedem Versatz eine
    # .orig-Kopie neben der Zieldatei an. Siehe remove_patch_leftovers.
    patch -p1 -f --ignore-whitespace --no-backup-if-mismatch <"$patch_file" \
      || patch_abort "$patch_file liess sich nicht anwenden."
    echo "  $patch_file: angewendet."
  fi

  [ -n "$check_file" ] || return 0
  [ -f "$check_file" ] \
    || patch_abort "$patch_file lief durch, aber $check_file fehlt."
  [ -n "$check_pattern" ] || return 0
  grep -q "$check_pattern" "$check_file" \
    || patch_abort "$patch_file lief durch, aber '$check_pattern' fehlt in $check_file."
}

# copy_into_tree <quelldatei> <zieldatei>
#
# Kopiert eine Datei in den Baum, sofern sie dort noch nicht liegt. Fuer die
# Patches, die nicht angewendet, sondern als Datei abgelegt werden (OpenWrt und
# der Kernel wenden sie selbst an).
copy_into_tree ()
{
  local source_file="$1"
  local target_file="$2"

  [ -f "$source_file" ] || patch_abort "$source_file nicht gefunden."

  if [ -f "$target_file" ]; then
    echo "  $target_file: liegt bereits im Baum."
    return 0
  fi

  [ -d "$(dirname "$target_file")" ] \
    || patch_abort "$(dirname "$target_file") gibt es nicht - passt der Pfad noch zum Baum?"
  cp "$source_file" "$target_file" || patch_abort "$source_file liess sich nicht kopieren."
  echo "  $target_file: kopiert."
}

# enter_dir <verzeichnis>
#
# cd mit Abbruch. Ohne die Pruefung laufen die folgenden Patches im falschen
# Baum, wenn das Verzeichnis fehlt.
enter_dir ()
{
  cd "$1" || patch_abort "Wechsel nach $1 nicht moeglich (Arbeitsverzeichnis: $PWD)."
}
