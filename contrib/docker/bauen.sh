#!/bin/bash
#
# Startet build.sh in der Bookworm-Bauumgebung.
#
#   contrib/docker/bauen.sh <build.conf> <targets.conf> <domains.conf> [target...]
#
# Alle Argumente gehen unveraendert an build.sh weiter.
#
#
# Der Kniff mit dem Pfad
# ----------------------
# Der Baum wird im Container unter DEMSELBEN absoluten Pfad eingehaengt wie auf
# dem Host. OpenWrt nimmt Pfade in die Signatur auf, mit der es entscheidet, ob
# ein Paket neu uebersetzt werden muss (.prepared<hash>). Haengt der Baum
# woanders, sind alle Stempel eines warmen Baums ungueltig und es geht von vorn
# los. Genau daran ist eine Kopie dieses Baums nach dem Umzug haengengeblieben.
#
#
# Warum ueberhaupt ein Container
# ------------------------------
# OpenWrt 23.05 ist gegen GCC 12/13 entstanden. Ubuntu 26.04 bringt GCC 15, und
# seit GCC 14 sind mehrere Warnungen Fehler. squashfs3-lzma und elfutils liessen
# sich noch mit -Wno-... ueberreden, das Host-Perl 5.28.1 nicht: sdbm.c
# deklariert malloc und free in K&R-Form, was mit den Standardheadern
# kollidiert, und weder -Wno-incompatible-pointer-types noch -fno-builtin
# haben das aufgeloest.
#
# Der Container ist die Antwort auf die Ursache statt auf die Symptome. Die
# Patches unter patches/host-tools-gcc15* und
# patches/openwrt-packages-perl.patch bleiben liegen, sind aber in prepare.sh
# nicht mehr aktiv - auf einem warmen Baum richten sie Schaden an, weil sie die
# Makefiles und damit die Signaturen aendern.

set -euo pipefail

BAUM="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
BILD="gluon-2023.2:bookworm"

if ! docker image inspect "$BILD" >/dev/null 2>&1; then
  echo "Bild $BILD fehlt. Einmalig bauen:" >&2
  echo "  docker build -t $BILD $BAUM/contrib/docker" >&2
  exit 1
fi

# /etc/localtime vom Host: sonst laeuft der Container in UTC, und die
# Stundenangabe in SBRANCH (SBRANCH_MODE=date, date +%y%m%d%H) weicht um ein
# bis zwei Stunden von einem Lauf auf dem Host ab. Das Bild hat kein tzdata;
# die eingehaengte Datei reicht glibc trotzdem.
#
# --network=host: "make download" holt Quellen, und der Bau laeuft in unserem
# Netz. Ohne das ginge es zwar auch, aber die Firmware-Server im eigenen Netz
# waeren nicht erreichbar.
exec docker run --rm -i \
  -u "$(id -u):$(id -g)" \
  --network=host \
  -v "$BAUM:$BAUM" \
  -v "$HOME/.gitconfig:$HOME/.gitconfig:ro" \
  -v /etc/localtime:/etc/localtime:ro \
  -w "$BAUM" \
  -e HOME="$BAUM" \
  "$BILD" \
  ./build.sh "$@"
