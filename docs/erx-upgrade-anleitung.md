# EdgeRouter X auf Gluon 2025.1 bringen

Anleitung zum Abarbeiten. Alle Befehle sind zum Kopieren gedacht.

Ersetze in allen Befehlen `NODE` durch die Adresse deines Knotens, zum Beispiel
`192.168.1.1` oder eine IPv6-Adresse in eckigen Klammern.

Du brauchst drei Dateien auf deinem Rechner:

* `erx-migrate.sh`
* `erx-migrate-stage2.sh`
* das neue Image, zum Beispiel `gluon-...-ubiquiti-edgerouter-x-ka-sysupgrade.bin`
  (beim EdgeRouter X SFP: `...-ubiquiti-edgerouter-x-sfp-ka-...`)

Rechne mit 5 Minuten. Der Knoten ist dabei etwa 2 Minuten nicht erreichbar.

---

## 1. Dateien auf den Knoten kopieren

**Wichtig:** `scp` funktioniert nicht, dem Knoten fehlt der passende Dienst. Es
geht so:

```sh
ssh root@NODE 'cat > /tmp/erx-migrate.sh'       < erx-migrate.sh
ssh root@NODE 'cat > /tmp/erx-migrate-stage2.sh' < erx-migrate-stage2.sh
ssh root@NODE 'cat > /tmp/erx-2025.bin'          < gluon-*-ubiquiti-edgerouter-x-ka-sysupgrade.bin
```

Prüfen, ob alles angekommen ist:

```sh
ssh root@NODE 'ls -l /tmp/erx-migrate.sh /tmp/erx-migrate-stage2.sh /tmp/erx-2025.bin'
```

Die dritte Datei muss mehrere Megabyte groß sein. Steht dort `0`, ist die
Übertragung fehlgeschlagen — dann den Befehl noch einmal ausführen.

---

## 2. Vorprüfung

```sh
ssh root@NODE 'sh /tmp/erx-migrate.sh --check'
```

Erwartete Ausgabe:

```
=== EdgeRouter-X-Migration, Vorpruefung ===
  Board:            ubnt,edgerouter-x
  compat_version:   1.1  (erwartet: leer oder 1.x)
  Layout:           alt (kernel1 + kernel2), vollstaendige Migration
  Boot-Index:       1 (0 = Slot 1)
  Watchdog-Marker:  nicht vorhanden (gut)
  Autoupdater-Lock: gehalten
  Stufe 2:          /tmp/erx-migrate-stage2.sh

Vorpruefung ohne Image bestanden. Mit Imagepfad erneut aufrufen.
```

**Wenn dort `Layout: neu` steht,** ist der Knoten bereits migriert. Dann ist
nichts weiter zu tun; ein normales `sysupgrade` genügt künftig.

**Wenn eine rote Fehlermeldung kommt,** hier abbrechen und nachfragen.

---

## 3. Migration starten

```sh
ssh root@NODE 'sh /tmp/erx-migrate.sh /tmp/erx-2025.bin'
```

Es kommt eine Rückfrage. Tippe `ja` und drücke Enter:

```
Dies schreibt Kernel und Rootfs neu. Die Konfiguration wird uebernommen,
der Versuch kann aber fehlschlagen - dann kommt das Geraet im Config-Mode hoch.
Fortfahren? (ja/nein)
```

Danach bricht die SSH-Verbindung ab. Das ist normal. Die letzte Zeile lautet
sinngemäß:

```
Command failed: ubus call system sysupgrade ... (Connection failed)
```

**Auch das ist normal.** Der Knoten arbeitet jetzt allein weiter.

---

## 4. Warten

Zwei Minuten nichts tun. Den Knoten in dieser Zeit **nicht** vom Strom trennen.

Danach prüfen, ob er wieder da ist:

```sh
ping6 NODE
```

oder

```sh
ssh root@NODE 'uptime'
```

---

## 5. Kontrolle

```sh
ssh root@NODE 'cat /lib/gluon/release; uname -r; ls /lib/modules/; cat /proc/mtd'
```

So sieht es richtig aus:

```
26110910bro
6.6.144
6.6.144
dev:    size   erasesize  name
mtd0: 00080000 00020000 "u-boot"
mtd1: 00060000 00020000 "u-boot-env"
mtd2: 00060000 00020000 "factory"
mtd3: 00600000 00020000 "kernel"
mtd4: 0f7c0000 00020000 "ubi"
```

Drei Dinge müssen stimmen:

1. Bei `uname -r` und bei `ls /lib/modules/` steht **dieselbe** Version.
2. Es gibt genau **eine** Partition namens `kernel`, nicht mehr `kernel1` und
   `kernel2`.
3. Die Größe von `mtd3` ist `00600000`.

Zum Schluss:

```sh
ssh root@NODE 'uci get system.@system[0].compat_version; cat /tmp/sysinfo/model'
```

Muss `2.0` ausgeben und darunter `Ubiquiti EdgeRouter X KA`.

---

## Wenn der Knoten nach 5 Minuten nicht wiederkommt

Nicht den Strom trennen, sondern melden. Der Knoten lässt sich über die serielle
Konsole und TFTP zurückholen, dafür braucht es aber jemanden mit dem passenden
Zubehör.

Vorher noch prüfen, ob er vielleicht unter einer anderen Adresse hochgekommen
ist: nach einer fehlgeschlagenen Übernahme der Konfiguration startet ein
Gluon-Knoten im Config-Mode und ist dann unter `192.168.1.1` erreichbar.

---

## Was danach anders ist

* Der Knoten läuft auf Gluon 2025.1 mit Kernel 6.6.
* Hostname, Position, Kontakt und die Mesh-Adressen bleiben unverändert.
* Künftige Updates laufen wieder als normales `sysupgrade`, auch automatisch.
* Ein Image für Gluon 2023.2 nimmt der Knoten nicht mehr an. Das ist Absicht.
* Das Modell heißt jetzt **Ubiquiti EdgeRouter X KA**, auf der Statusseite und
  auf der Karte. Das `KA` steht für das neue Flash-Layout. Ein EdgeRouter X
  ohne `KA` ist ein Knoten, der die Migration noch vor sich hat.
