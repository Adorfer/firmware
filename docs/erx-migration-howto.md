# EdgeRouter X auf Gluon 2025.1 migrieren — mit Konfigurationserhalt

Stand 2026-09-09. Entstanden bei Freifunk Neanderland, an einem Geraet
durchgefuehrt und dabei siebenmal gescheitert. Was hier steht, ist das
Ergebnis; die Fallstricke stehen dabei, weil sie sich alle wiederholen werden.

Gemeindespezifisches ist bewusst herausgelassen. Wo eure Pakete betroffen sein
koennten, steht es als Frage, nicht als Anweisung.

## Gilt auch fuer den ERX-SFP

Beides, `ubnt,edgerouter-x` und `ubnt,edgerouter-x-sfp`, teilt sich alles, was
hier zaehlt:

* dieselbe Partitionstabelle — beide `.dts` binden
  `mt7621_ubnt_edgerouter-x.dtsi` ein, also `factory` bei 0x0e0000, `kernel1`
  bei 0x140000 und `kernel2` bei 0x440000;
* dieselbe Geraetedefinition `Device/ubnt_edgerouter_common`, damit auch
  dieselbe `KERNEL_SIZE` und dieselbe `compat_version`;
* denselben Upgrade-Pfad: OpenWrts `platform.sh` fuehrt beide Boards in einer
  `case`-Zeile zu `platform_upgrade_ubnt_erx`;
* denselben Boot-Index bei Offset 160, `UBNT_ERX_KERNEL_INDEX_OFFSET` ist
  board-unabhaengig.

Der SFP unterscheidet sich nur in der Peripherie (`kmod-i2c-algo-pca`,
`kmod-gpio-pca953x`, `kmod-sfp`) — bei uns rund 20 KB mehr im Image, am Flash
aendert das nichts.

**Getestet ist es trotzdem nicht.** Alle Durchgaenge liefen auf einem ERX ohne
SFP. Die Vorpruefung mit `--check` laeuft ohne jedes Risiko und zeigt vorab, ob
Layout und Boot-Index wie erwartet aussehen; das waere der erste Schritt auf
einem SFP.

---

## Kurzfassung

**Problem:** Kernel 6.6 ist 27 KB zu gross fuer den 3-MB-Slot des ERX.

**Loesung:** Nicht umpartitionieren — das Layout steht in der DTS. Physisch
aendert sich **ein Byte**: der Boot-Index in `factory` bei Offset 160 auf
`0x00`. Dazu den Kernel ueber die Grenze `kernel1`→`kernel2` schreiben und das
Rootfs wie bei jedem sysupgrade.

**Vorlage:** <https://github.com/darkxst/erx-migration>. Funktioniert, verliert
aber die Konfiguration. Der Zusatz hier: `sysupgrade -b` vorweg,
`nand_restore_config` danach — zwei Zeilen.

**Fuenf Dinge, an denen es scheitert:**

1. Im RAM-Root von sysupgrade fehlen `head` und `hexdump`. Fehlende Werkzeuge
   liefern **leere Ausgaben, keine Fehler** — und die sehen aus wie ein Befund.
   Nur `dd`, `md5sum`, `mtd`, `ubi*` benutzen und auf leere Eingabe pruefen.
2. Lesen ueber `/dev/mtdN` (Char), einzelne Bytes schreiben ueber
   `/dev/mtdblockN` (Block). Andersherum vergleicht ihr den Seitencache bzw.
   bekommt „non page aligned data".
3. Nach dem Kernelschritt heissen die Partitionen `kernel` statt
   `kernel1`/`kernel2`. Skripte muessen **beide Layouts** koennen, sonst ist ein
   abgebrochener Lauf nicht fortsetzbar.
4. Cron-getriebene Watchdogs eurer Pakete rebooten mitten hinein. Anhalten,
   nicht nur markieren — und `pgrep` **ohne** `-f`, sonst trefft ihr euch selbst.
5. `compat_version` kommt mit der zurueckgespielten Konfiguration als `1.x`
   wieder herein. Auf `2.0` nachziehen.

**Rueckweg:** Serielle Konsole, 57600. Ralink-Bootmenue, **Ziffer 1** startet
ein Image aus dem RAM ohne den Flash anzufassen. Ctrl-C hilft dort nicht.

**Geschafft, wenn:** `uname -r` und `ls /lib/modules/` dieselbe Version zeigen.
Weichen sie ab, ist nur der Kernel geschrieben und das Rootfs fehlt.

---

## Worum es geht

Gluon 2025.1 bringt Kernel 6.6. Der passt auf dem EdgeRouter X nicht mehr in
einen Kernel-Slot:

| | Bytes | |
| --- | ---: | --- |
| Kernel 6.6 (ERX) | 3 173 556 | 3,03 MB |
| alter Slot `kernel1` / `kernel2` je | 3 145 728 | 3,00 MB |
| **Ueberschuss** | **27 828** | **27 KB** |
| neuer Slot `kernel` | 6 291 456 | 6 MB |

Gluon nennt den ERX in den Release Notes zu 2025.1 ausdruecklich als Geraet,
das manuelle Schritte braucht, und verweist auf
<https://github.com/darkxst/erx-migration>. Freifunk Lippe hat daraus eine
Anleitung gemacht, 4830.org betreibt sie auf rund 80 Geraeten.

**Was dieses HOWTO zusaetzlich leistet: die Konfiguration bleibt erhalten.** Bei
der Vorlage kommt der Knoten im Config-Mode hoch und muss neu eingerichtet
werden — was bei Geraeten, an die niemand herankommt, das eigentliche Problem
ist.

## Was dabei wirklich passiert

**Es wird nicht umpartitioniert.** Die Partitionstabelle steht in der DTS der
Firmware, nicht im Flash. Physisch aendert sich genau ein Byte.

| | alt | neu |
| --- | --- | --- |
| `u-boot`, `u-boot-env`, `factory` | `0x000000`, `0x080000`, `0x0e0000` | unveraendert |
| Kernel | `kernel1` `0x140000` +3M, `kernel2` `0x440000` +3M | **`kernel` `0x140000` +6M** |
| `ubi` | `0x740000` +247M | **unveraendert** |

Der neue 6-MB-Slot deckt genau die beiden alten ab. **`ubi` bleibt, wo es ist**
— der Rootfs-Bereich ist von der Layoutaenderung gar nicht beruehrt.

Die Migration besteht damit aus drei Schritten:

1. Den neuen Kernel ueber die Grenze `kernel1` → `kernel2` schreiben.
2. Den UBNT-Boot-Index in `factory` bei **Offset 160** auf `0x00` setzen, damit
   U-Boot immer aus Slot 1 startet.
3. Das Rootfs ins `ubi` schreiben, wie bei jedem sysupgrade.

Der Boot-Index steuert, ab welcher Adresse U-Boot laedt — nachpruefbar am
Bootlog, dort steht `k_idx=` und die geladene Adresse:

```
k_idx=0  ->  ## Booting image at bfd40000     (kernel1)
k_idx=1  ->  ## Booting image at c0040000     (kernel2, 0x300000 weiter)
```

## Voraussetzungen

* **Ein Gluon-2025.1-Image fuer `ubiquiti-edgerouter-x`.** Ohne das ist die
  Migration gegenstandslos.
* **Serielle Konsole, 57600 8N1.** Nicht optional — sie ist der einzige
  Rueckweg, wenn zwischen Kernel und Rootfs etwas schiefgeht.
* **Netzzugang zum Knoten**, um Image und Skripte zu uebertragen.
* **Ein RAM-startfaehiges Rettungsimage** im TFTP-Verzeichnis, fuer den Fall
  der Faelle:
  `openwrt-24.10.x-ramips-mt7621-ubnt_edgerouter-x-initramfs-kernel.bin`
* **Ein voller Flash-Dump**, falls ihr ihn wollt. Wir haben ihn nie gebraucht.

Die SPI-Flash-Klammer hilft hier **nicht**: der ERX hat paralleles NAND
(`AMD/Spansion S34ML02G2`, TSOP-48), keinen SPI-NOR.

## Vorher pruefen

```sh
cat /proc/mtd                                   # kernel1+kernel2 oder schon kernel?
uci -q get system.@system[0].compat_version     # 1.x = noch nicht migriert
dd if=/dev/mtd2 bs=1 skip=160 count=1 2>/dev/null | md5sum
#   93b885adfe0da089cdf634904fd59f71 = 0x00, bootet kernel1
#   55a54008ad1ba589aa210d2629c1df41 = 0x01, bootet kernel2
```

Und die Kernelgroesse im Zielimage — ist sie kleiner als 3 MB, braucht ihr die
Migration gar nicht:

```sh
tar tvf gluon-...-edgerouter-x-sysupgrade.bin | awk '/\/kernel$/{print $3}'
```

## Der Ablauf

Zweistufig, weil das laufende System sich dabei selbst abbaut. Stufe 1 prueft
und uebergibt per `ubus call system sysupgrade` mit eigenem `command` an
Stufe 2, die aus dem RAM-Root laeuft.

**Stufe 1**, auf dem laufenden Knoten:

```sh
# 1. Konfiguration sichern. Ohne das ist sie nach dem Neuaufbau der
#    UBI-Volumes weg - genau daran scheitert die Vorlage.
sysupgrade -b /tmp/sysupgrade.tgz

# 2. Alles anhalten, was rebooten koennte (siehe unten).

# 3. Uebergeben
ubus call system sysupgrade '{"prefix":"/tmp/root","path":"/tmp/image.bin",
                              "force":true,"command":"sh /tmp/stage2.sh",
                              "options":{"save_partitions":0}}'
```

**Stufe 2**, im RAM-Root:

```sh
# Kernel schreiben, ueber die Slotgrenze
dd if=$kernel bs=1024 count=3072 | mtd write - kernel1
dd if=$kernel bs=1024 skip=3072  | mtd write - kernel2

# Zurueckelesen und vergleichen, BEVOR der Boot-Index umgesetzt wird
# (Details unten - hier lauern zwei Fallen)

# Boot-Index auf 0
printf '\000' | dd of=/dev/mtdblock2 bs=1 count=1 seek=160 conv=notrunc

# Rootfs
nand_upgrade_prepare_ubi "$rootfs_len" "$rootfs_type" "" "0"
ubiupdatevol /dev/$root_ubivol -s "$rootfs_len" "$rootfs_file"

# Konfiguration zurueckspielen - DAS ist der Unterschied zur Vorlage
nand_restore_config /tmp/sysupgrade.tgz
```

`nand_restore_config` kommt aus `/lib/upgrade/nand.sh` und liegt auf dem Geraet
schon bereit: es haengt das frische `rootfs_data` ein und legt das Archiv als
`sysupgrade.tgz` hinein, wo der Preinit des neuen Systems es findet. Derselbe
Weg, den ein normales sysupgrade nimmt.

## Die Fallstricke

### Der RAM-Root ist eine karge Umgebung

`sysupgrade` baut fuer Stufe 2 einen RAM-Root mit einer festen, kleinen
Programmliste. **`head` und `hexdump` sind dort nicht vorhanden.**

Und das ist die eigentliche Gemeinheit: **fehlende Programme melden keinen
Fehler, sie liefern eine leere Ausgabe.** Die sieht dann aus wie ein Befund.
`md5sum` von nichts ist `d41d8cd98f00b204e9800998ecf8427e` — das liest sich wie
ein zerschossener Kernel und hat uns zwei Laeufe mitten im Vorgang abgebrochen.

Verwendet in Stufe 2 nur `dd`, `md5sum`, `mtd`, die `ubi*`-Werkzeuge und die
Shell. Und **prueft jede Pruefung auf leere Eingabe**:

```sh
soll="$(dd if="$kernel" bs=4096 count="$bl" 2>/dev/null | md5sum | cut -d' ' -f1)"
[ -n "$soll" ] && [ "$soll" != "d41d8cd98f00b204e9800998ecf8427e" ] \
    || { echo "Sollsumme leer - fehlt ein Werkzeug?" >&2; exit 1; }
```

### Block- oder Char-Geraet, je nach Richtung

`find_mtd_part` liefert das **Block**-Geraet (`/dev/mtdblockN`). Das ist
seitengepuffert:

* **Lesen** ueber das Char-Geraet (`/dev/mtdN`), sonst vergleicht ihr den Cache
  statt des Flashs.
* **Schreiben** einzelner Bytes ueber das Block-Geraet. Ein Ein-Byte-Schreiben
  aufs Char-Geraet lehnt der NAND-Treiber ab:
  `nand_do_write_ops: attempt to write non page aligned data`. `mtdblock` macht
  das noetige Lesen-Aendern-Schreiben der Seite.

### Nach dem Kernelschritt heissen die Partitionen anders

Bricht ein Lauf nach dem Kernel ab, bootet das Geraet mit der **neuen DTS**.
`/proc/mtd` zeigt dann `kernel` statt `kernel1`/`kernel2`, und ein Skript, das
nur die alten Namen kennt, verweigert die Fortsetzung mit
„kernel1/kernel2 nicht gefunden". Der Knoten steht dann mit **neuem Kernel auf
altem Rootfs**: lauffaehig, aber ohne passende Module und damit ohne Netz.

**Baut eure Skripte so, dass sie beide Layouts erkennen.** Fuer ein
Fernverfahren ist das keine Bequemlichkeit, sondern die Bedingung dafuer, dass
man es ueberhaupt aus der Ferne machen darf.

### Der Abbruch schuetzt nicht immer

Die uebliche Absicherung — „Boot-Index erst nach bestandener Pruefung setzen" —
unterstellt, dass der Index bis dahin auf den **alten** Kernel zeigt. Das gilt
nicht, wenn der letzte regulaere Upgrade-Lauf ihn schon umgelegt hat. Steht er
bereits auf `0`, bootet U-Boot sofort den frisch geschriebenen Slot 1, ob ihr
den Index nun anfasst oder nicht.

### Cron-getriebene Reboots

**Pruefen, ob eure Community-Pakete etwas mitbringen, das von sich aus
rebootet.** Bei uns war es ein Deadman-Watchdog, der alle fuenf Minuten per
cron startet und in einer Schleife schlaeft:

```sh
while : ; do
    if ! sleep "$slice" ; then
        reboot_now "unable to fork (out of memory?)"
    fi
```

`sysupgrade` schickt beim Abbau TERM und KILL an alle Prozesse. Damit stirbt
das `sleep`, die Bedingung greift, und der Watchdog rebootet **hart ueber
sysrq** — mitten in den Flash-Vorgang. Es ist kein Speichermangel, es ist das
Signal.

Ein Marker, den solche Skripte pruefen, hilft nur, wenn er **vor** dem Start
der Instanz da ist. Eine schon laufende Instanz sieht ihn nicht. Also die
Instanz beenden:

```sh
/etc/init.d/micrond stop
kill $(pgrep watchdog.sh)
```

**Ohne `-f`.** `pgrep -f` durchsucht die ganze Kommandozeile und findet damit
auch euer eigenes Migrationsskript, sobald der Pfad darin vorkommt — ihr
erschiesst euch dann mitten im Vorgang selbst. BusyBox setzt `comm` bei
Skripten auf den Skriptnamen, der Name ohne Pfad genuegt.

### `compat_version` kommt mit der Konfiguration zurueck

Der Wert steht in `/etc/config/system` und wird mit dem zurueckgespielten
Archiv **als 1.x wieder hereingetragen** — obwohl das Geraet danach auf dem
neuen Layout laeuft. Es behauptet also, unmigriert zu sein, und jedes Werkzeug,
das darauf prueft, haelt es weiterhin fuer migrierbar.

Wer die Konfiguration verliert, sieht das nie. Nachziehen:

```sh
uci set system.@system[0].compat_version=2.0 && uci commit system
```

## Wenn es schiefgeht

Der ERX hat einen Ralink-UBoot mit **Nummernmenue**, kein „Hit any key":

```
Please choose the operation:
   1: Load system code to SDRAM via TFTP.            <- RAM-Boot, Flash unberuehrt
   2: Load system code then write to Flash via TFTP. <- schreibender Rueckweg
   3: Boot system code via Flash (default).
   4: Entr boot command line interface.
```

Ctrl-C-Dauerfeuer laeuft hier ins Leere — es muss eine **Ziffer** getippt
werden. Option 1 ist der sichere Einstieg: sie startet ein Image aus dem RAM,
ohne den Flash anzufassen.

Ist der Knoten nur halb migriert (neuer Kernel, altes Rootfs), reicht oft
schon die serielle Konsole plus eine Adresse von Hand — dann laesst sich das
Image erneut uebertragen und der Lauf fortsetzen. Bei uns hat das jedes Mal
genuegt; das Rettungsimage kam nie zum Einsatz.

## Pruefen, ob es geklappt hat

```sh
uname -r                                # 6.6.x
cat /lib/gluon/gluon-version            # v2025.1.x
cat /proc/mtd                           # ein "kernel" mit 0x600000, kein kernel1/2
ls /lib/modules/                        # muss zur Kernelversion passen!
uci -q get system.@system[0].compat_version   # 2.0
```

`/lib/modules/` ist der wichtigste Punkt: steht dort eine andere Version als
bei `uname -r`, ist nur der Kernel geschrieben worden und das Rootfs fehlt.
Genau das ist der halb migrierte Zustand.

Und danach der uebliche Blick: bootet er kalt, ist er im Mesh, kommt der
VPN-Tunnel hoch.

## Was passiert, wenn ein migrierter Knoten ein altes Image bekommt

Zwei Faelle, beide am migrierten Geraet gemessen (09.09.2026):

**Er bekommt das Migrationsimage noch einmal.** Unkritisch. Das Skript liest
den Boot-Index und die Partitionsnamen, erkennt am Namen `kernel` das neue
Layout und schreibt einfach in denselben 6-MB-Slot. Der Index steht schon auf
`0x00`, `ubnt_update_kernel_flag()` steigt frueh aus, ohne den Flash
anzufassen. Ein Reflash desselben Zustands.

**Er bekommt ein 2023.2-sysupgrade.** Wird abgelehnt, bevor irgendetwas
geschrieben wird — von OpenWrts eigener Maschinerie, nicht von uns:

```
upgrade: The device is supported, but this image is incompatible for sysupgrade
         based on the image version (2.0->1.1).
upgrade: Config cannot be migrated from swconfig to DSA
Image check failed.
```

`fwtool_check_image()` vergleicht die Hauptversionen von Geraet und Image und
verweigert bei Ungleichheit. Das Geraet meldet nach der Migration `2.0` (aus
`ubnt_edgerouter_common` in OpenWrts `mt7621.mk`), das alte Image traegt `1.1`.
Der Knoten lief waehrend des Versuchs ununterbrochen weiter, Boot-Index und
Kernel-Slot unveraendert.

**Eine Ewigkeitslast entsteht daraus nicht.** Wir setzen die `compat_version`
nirgends selbst — sie kommt aus dem 24.10-Baum. Steigt sie dort irgendwann auf
3.0, geht das genauso von allein mit.

### Die Falle dabei: der Konfigurationserhalt

Der Schutz haengt daran, dass das Geraet die `2.0` auch wirklich meldet. Und
genau da hat der Konfigurationserhalt ein Loch: `/etc/config/system` liegt im
Overlay, wandert also in `sysupgrade -b`, und `/bin/config_generate` schreibt
seine eigene `compat_version` nur, wenn die Datei fehlt oder leer ist
(`[ ! -s /etc/config/system ]`). Die wiederhergestellte Datei gewinnt — ein
migrierter Knoten stuende danach wieder auf `1.1`.

Gemessen, mit `uci set` ohne `commit` (also ohne einen einzigen
Flash-Schreibvorgang):

| Geraet meldet | `sysupgrade` mit dem 2023.2-Image |
|---|---|
| `compat_version 2.0` | `Image check failed`, Exitcode 1 |
| `compat_version 1.1` | **Exitcode 0** — das Image wuerde geschrieben |

Was dann folgt, ist die eigentliche Falle: ein 3-MB-Kernel landet im 6-MB-Slot
bei Index `0`, das alte Rootfs erwartet aber wieder A/B-Slots und schreibt beim
naechsten Update auf `kernel2`, das es nicht mehr gibt. Auffallen wuerde das
erst beim uebernaechsten Boot.

Deshalb hebt das Migrationsskript die `compat_version` in der gesicherten
Konfiguration selbst an, bevor sie zurueckgespielt wird — der Zielwert kommt
aus den Metadaten des Images, gelesen mit `fwtool -q -i`.

## Noch offen

* **Vollautomatisch aus der Ferne**, ausgeloest ueber den Autoupdater. Die
  Bausteine stehen; was fehlt, ist die Ausloesung ohne Handgriff am Knoten.
* **Rueckweg auf das alte Layout.** Von `0x00` zurueck auf `0x01` muesste ein
  Bit von 0 auf 1 — auf NAND geht das nur mit Loeschen des ganzen
  Eraseblocks, und in dem stehen auch die MAC-Adressen. Der gangbare Weg ist
  ein Rueckweg, der mit Index `0` auskommt: den alten Kernel nach Slot 1
  schreiben und `kernel2` unbenutzt lassen. Ungeprueft.
* **Bad Blocks.** `mtd write` ueberspringt sie. Liegt einer in `kernel1`,
  passen die ersten 3 MB nicht mehr hinein und der Kernel wird still
  zerschnitten. Mit den Werkzeugen im Gluon-Image laesst sich die Markierung
  nicht abfragen — das Zurueckelesen faengt die Folge ab, nicht die Ursache.
  Unser Geraet war sauber; ueber eine Flotte sagt das nichts.
