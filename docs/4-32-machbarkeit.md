# Gluon 2023.2.x auf 4/32-Geräten — Machbarkeit

Untersuchung, Stand 2026-09-05. **Nur Analyse, nichts umgesetzt.**

> **Kurzfassung:** Nein. Es fehlen rund **1300 KiB**, und der Luxus, den man dafür
> streichen würde — Statusseite, Config-Mode, uhttpd — ist davon **76 KiB**. Die Wand
> ist der Kernel: er belegt allein 59 % des gesamten Platzbudgets.
>
> Der praktisch verwertbare Teil dieser Aufstellung ist **Kapitel 7**: die
> Squashfs-Blockgröße, die beim nächsten Bau des 2021.1.2-Zweigs zu prüfen ist.

Ergänzt `migration-2025.1-targets.md`, wo die 4/32-Klasse als „eigenes Thema"
ausgeklammert ist. Dies ist dieses Thema.

## 1. Das Gerät und sein Budget

Der TP-Link TL-WR841N/ND v12 — stellvertretend für die ganze Klasse — hat
**4 MB Flash und 32 MB RAM**.

Gute Nachricht zuerst: **OpenWrt 23.05 kennt das Gerät noch.** Die Device-Trees für
v9/v10/v11/v12 liegen in `target/linux/ath79/dts/`, und `tiny-tp-link.mk` führt
`TARGET_DEVICES += tplink_tl-wr841-v12`. Portieren müsste man also nichts. Gebaut wird
es nur nicht, weil in `common-tp-link.mk` steht:

```make
define Device/tplink-4mlzma
  TPLINK_FLASHLAYOUT := 4Mlzma
  IMAGE_SIZE := 3904k
  DEFAULT := n
endef
```

**3904 KiB** ist damit das harte Budget für Kernel *und* Rootfs zusammen.
`DEFAULT := n` heißt: aus dem Release-Bau genommen, auf Wunsch baubar.

Gluon selbst führt seit mindestens v2021.1.x kein 4/32-Gerät mehr — weder ein
`ath79-tiny`-Target noch einen 841 in `ath79-generic`. Die Geräte, die im
Neanderfunk-Bestand laufen, sind seinerzeit über eigene Patches hineingekommen.

## 2. Messreihe: wie klein wird das Rootfs?

**Methode.** Das Sysupgrade-Image vom 2026-09-04 (`01_vel`, alfa-network-ap121f,
ath79-generic) wurde ausgepackt, schrittweise abgemagert und nach jedem Schritt mit
`mksquashfs -comp xz -b 262144` neu gepackt. Kontrolle: Variante A ergibt 4460 KiB
gegen 4481 KiB im echten Image — die Methode liegt 0,5 % darunter, weil der
MIPS-BCJ-Filter lokal fehlt. Für eine Aussage über Größenordnungen reicht das.

| Variante | Rootfs komprimiert | Differenz |
|---|---|---|
| A) Original, alle Neanderfunk-Pakete | 4460 KiB | — |
| B) **ohne Statusseite, Config-Mode, uhttpd, gluon-web, iwinfo** | 4384 KiB | **−76 KiB** |
| C) B, zusätzlich ohne opkg, socat, TLS-Stack, CA-Zertifikate | 3420 KiB | −1040 KiB |
| D) C, zusätzlich ohne USB/SCSI, QoS, dnsmasq | 2932 KiB | −1528 KiB |

Die Zeile, um die es geht, ist **B**. Der komplette Verzicht auf die Weboberfläche —
die Idee, mit der man normalerweise anfängt — bringt 76 KiB. Das ist Rundungsrauschen.

Was in Variante D übrig bleibt, ist kein Luxus mehr: hostapd (780 KiB),
mac80211 (736 KiB), libc (708 KiB), ath9k_hw (414 KiB), cfg80211 (355 KiB),
busybox (320 KiB), dropbear (258 KiB), batman-adv (235 KiB) — unkomprimiert.

## 3. Die Rechnung

Der Kernel desselben Builds (uImage, lzma) misst **2304 KiB**.

```
Budget                          3904 KiB
Kernel                        − 2304 KiB   (59 % des Budgets)
                              ──────────
für das Rootfs übrig            1600 KiB
schlankste gemessene Variante   2932 KiB
                              ──────────
Fehlbetrag                    − 1332 KiB   (Rootfs 83 % über dem Rest)
```

Selbst wenn man den Kernel durch Trimming und fest eingebaute Module auf 1,8 MB
drückte, müsste das Rootfs von 2932 auf unter 2100 KiB — aus einem Bestand, in dem
hostapd, mac80211 und libc allein schon 2,2 MB unkomprimiert stellen.

**Billiger Gegentest**, falls man es schwarz auf weiß will (ein halber Tag): eine
Datei `targets/ath79-tiny` in Gluon 2023.2 anlegen mit
`device('tp-link-tl-wr841n-v12', 'tplink_tl-wr841-v12', { class = 'tiny' })`, im
`image-customization.lua` den `device_class('tiny')`-Zweig radikal leerräumen, bauen.
Der Build nennt die Überschreitung selbst. Erwartung nach obiger Rechnung: ~1300 KiB.

## 4. Der Weimarer Vortrag von 2018 — und was davon bleibt

„Fight for the bytes! Fun with Four Megabytes Flash", **mt (weimarnetz.de)**,
35C3 OIO, 28.12.2018, 22 Minuten. Untertitel gibt es nicht; der Inhalt hier stammt aus
dem Foliensatz.

Seine Layout-Folie ist der aufschlussreichste Vergleich, den diese Aufstellung
enthält — beide Kernelzahlen sind ohne WLAN-Module, also direkt vergleichbar:

| | 2018 (Kernel 4.14) | 2026 (Kernel 5.15, euer Build) |
|---|---|---|
| U-Boot | 128 KB | 128 KB |
| **Kernel** | **1,2 MB** | **2,3 MB** |
| Userland (SquashFS) | **1,8–3,6 MB** | **≈1,6 MB** |

**Der Kernel hat sich verdoppelt und dabei den Platz fürs Userland halbiert.** Das ist
die ganze Geschichte in zwei Zeilen.

Seine RAM-Folie sagt für die zweite Hälfte dasselbe: *32 MB ≈ 11–16 MB nutzbar*, weil
der **dekomprimierte Kernel 4–6 MB** belegt, dazu procd, ubusd, uhttpd, Routing-Daemon.
Das galt für 4.14.

Sein Maßnahmenkatalog, heute bewertet:

| Vorschlag 2018 | Ertrag 2026 |
|---|---|
| Bye Bye LuCI | Gluon hat keins; das Äquivalent sind die gemessenen **76 KiB** |
| Bye Bye opkg | in Variante C enthalten; mit TLS/Zertifikaten zusammen ≈ 1 MB |
| Bye Bye Debug-Symbole | seit Jahren Standard, nichts mehr zu holen |
| binsort (ähnliche Dateien zusammen sortieren) | seine eigene Zahl: **30–100 KB** |
| busybox-Config kürzen | sein eigener Satz: *„don't expect huge gains"* |
| kein USB | in Variante D bereits raus |
| kein IPv6, kein 802.11s | für Freifunk beides nicht verhandelbar |
| **Kernel-LTO** | die interessanteste Idee — und weiter versperrt: `ARCH_SUPPORTS_LTO_CLANG` gibt es in aktueller Mainline für arm64 und x86, **für MIPS nicht**. Das GCC-Patchset von Andi Kleen ist nie gelandet |
| ubus/rpcd statt mitgelieferter Oberfläche | elegant (*„Your Router is a RPC-API endpoint. Website can be everywhere"*) — es geht aber um jene 76 KiB |

Aufsummiert bewegt sich der Katalog im Bereich einiger hundert Kilobyte, gegen einen
Fehlbetrag von 1332 KiB. 2018 war die Lücke klein genug, dass so eine Liste sie
schließen konnte. Genau deshalb klang der Vortrag zuversichtlich.

## 5. Hat es jemand geschafft?

**Für Gluon: niemand**, den ich finden konnte — keine Community, kein Fork, kein
dokumentierter Versuch nach 2021.

**Für blankes OpenWrt** ist die Lage im Thread „Ultimate Guide for 4MB flash devices"
dokumentiert (zuletzt aktiv 2024):

> **Mijzelf, 2023-06-08:** „since dec '20 the default kernel + squashfs has grown by
> 50%. So the firmware you could squeeze in 4MB back in 2020 now needs an extra 2MB to
> squeeze away. You can try, but I think it's mission impossible."
>
> **kent_c, 2023-07-02:** „It's not impossible. I successfully built 22.03.5 for 4MB
> devices."

Zweimal um seine `diffconfig` gebeten, hat kent_c sie nie gezeigt. Und das war OpenWrt
ohne batman-adv, ohne VPN, ohne respondd. Der Autor des Threads hatte 2020 auf
19.07/21.02-Basis ein 4-MB-Image mit LuCI, WireGuard und SQM auf 3,6 MB gebracht — mit
Treiber-Trimming und fest eingebauten Kernelmodulen.

Der Weg, der nachweislich funktioniert, ist Hardware: der c't-Artikel „Organspende"
(Flash auf 8/16 MB, RAM auf 64 MB löten) hat viele Nachahmer gefunden. Bei zwei
Bastelstücken schön, bei 235 Knoten keine Option.

## 6. Der Bestand im Feld

Aus `https://map.eulenfunk.de/data/nodes.json`, 1199 Knoten:

| Gerät | Knoten |
|---|---|
| TL-WR841N/ND v9 | 89 |
| TL-WR841N/ND v10 | 64 |
| TL-WR841N/ND v11 | 39 |
| TL-WR940N v6 | 12 |
| TL-WR841N/ND v8 | 9 |
| TL-WR940N v4 | 9 |
| TL-WR941N/ND v6 | 4 |
| TL-WR741N/ND v1 | 3 |
| TL-WR941N/ND v2 | 2 |
| TL-WR740N/ND v4, TL-WR741N/ND v4, TL-WA801N/ND v2, TL-WA901N/ND v3 | je 1 |
| **Summe** | **235** (217 online) |

Das sind **20 % des Netzes**. Ihre Firmware-Basis:

| Basis | Knoten |
|---|---|
| `gluon-v2021.1.2-*` | 218 |
| `gluon-v2016.1-248-ge5acba5` | 15 |
| `gluon-v2020.2.2`, `gluon-v2016.2.7` | je 1 |

Der Museumszweig existiert also längst und trägt die Klasse.

## 7. Für einen künftigen 2021.1.2-Rebuild: Blockgröße und Fragment-Cache

Das ist der Teil dieser Aufstellung, der **heute** etwas bringt — unabhängig von jedem
2023.2-Versuch.

### Die Mechanik

Squashfs komprimiert blockweise. Die Blockgröße bestimmt drei Dinge auf einmal:

1. **Kompressionsgrad** — größere Blöcke packen besser, das Image wird kleiner.
2. **Fragment-Cache** — `CONFIG_SQUASHFS_FRAGMENT_CACHE_SIZE` Blöcke bleiben im RAM.
3. **Dekompressions-Puffer** — bei xz entspricht das Wörterbuch der Blockgröße
   (`fs/squashfs/xz_wrapper.c` setzt `dict_size` auf die Blockgröße). Bei 1 MB Blöcken
   ist allein das Wörterbuch 1 MB pro Dekompressor-Instanz.

Auf 32 MB RAM ist das kein Detail.

### Was OpenWrt selbst dazu sagt

`config/Config-images.in` und `Config-kernel.in`, in 21.02 wie in 23.05 gleich:

```
config TARGET_SQUASHFS_BLOCK_SIZE
	default 64 if LOW_MEMORY_FOOTPRINT
	default 1024 if (SMALL_FLASH && !LOW_MEMORY_FOOTPRINT)
	default 256

config KERNEL_SQUASHFS_FRAGMENT_CACHE_SIZE
	default 2 if (SMALL_FLASH && !LOW_MEMORY_FOOTPRINT)
	default 3
```

Und hier der Fund: **das `ath79/tiny`-Subtarget hat zwischen den Releases `low_mem`
dazubekommen.**

| | `target/linux/ath79/tiny/target.mk` | ergibt |
|---|---|---|
| OpenWrt 21.02 | `FEATURES += small_flash` | Blockgröße **1024 KiB**, Cache **2** → **2048 KiB RAM** |
| OpenWrt 23.05 | `FEATURES += low_mem small_flash` | Blockgröße **64 KiB**, Cache **3** → **192 KiB RAM** |

OpenWrt hat also genau diese Stellschraube nachgezogen — nach dem Zeitpunkt, an dem
euer 2021.1.2-Zweig entstanden ist.

### Was es kostet

Gemessen am echten Rootfs des 2023.2-Builds (gleiche Inhalte, nur andere Blockgröße):

| Blockgröße | Rootfs | Fragment-Cache (3 Blöcke) |
|---|---|---|
| 1024 KiB | 4284 KiB | 3072 KiB |
| **256 KiB** (heutiger Stand) | 4460 KiB | 768 KiB |
| 128 KiB | 4648 KiB | 384 KiB |
| 64 KiB | 4772 KiB | 192 KiB |

Von 1024 auf 64 KiB kostet **488 KiB Flash** und spart **2880 KiB Fragment-Cache**,
dazu den kleineren xz-Puffer. Auf einem 4-MB-Gerät ist ein halbes Megabyte viel — auf
einem Gerät, das an 32 MB RAM erstickt, sind knapp 3 MB womöglich mehr wert.

### Erster Schritt: nachsehen, was der Zweig überhaupt benutzt

Der Superblock verrät es. Auf ein beliebiges Sackgassen-Sysupgrade-Image angewendet:

```python
import struct
d = open('image.bin', 'rb').read()
o = d.find(b'hsqs')
bs, = struct.unpack_from('<I', d, o + 12)
print(bs // 1024, 'KiB Blockgröße')
```

Das aktuelle 2023.2-Image liefert damit 256 KiB, xz, Squashfs 4.0.

Für den 2021.1.2-Zweig sind zwei Fälle denkbar:

* **1024 KiB** — die 841 kamen über ein Target mit `small_flash` herein. Dann liegen
  2 MB RAM im Fragment-Cache, und die Umstellung ist die lohnendste Einzelmaßnahme,
  die dieser Zweig noch zu bieten hat.
* **256 KiB** — die Geräte kamen über `ath79-generic`. Dann sind es 768 KiB, und der
  Schritt auf 64 KiB spart noch 576 KiB für 488 KiB Flash.

Gesetzt wird beides in der Gluon-Targetdatei, die `config()`-Aufrufe an die
OpenWrt-Konfiguration durchreicht:

```lua
config('TARGET_SQUASHFS_BLOCK_SIZE', 64)
config('KERNEL_SQUASHFS_FRAGMENT_CACHE_SIZE', 2)
```

Zweite, kleinere Schraube am selben Ort: `CONFIG_SQUASHFS_DECOMP_MULTI_PERCPU` steht
im generischen Kernel-Config auf `y`. `SQUASHFS_DECOMP_SINGLE` hält nur eine
Dekompressor-Instanz vor — auf einem Einkerner ohnehin die passende Wahl.

### Ehrliche Einordnung

Genau das war 2019 schon einmal Thema, im Forumsthread „We have tons of 4MB/32MB
memory devices". Der damalige Befund von Gluon-Seite: die Blockgröße allein hat das
OOM-Problem **nicht** gelöst, und der Verdacht stand im Raum, dass ein tieferliegender
Fehler mitspielt. Es ist also eine Entlastung, keine Heilung.

Und zwei verbreitete Hoffnungen tragen hier nicht:

* **zram-Swap** hilft strukturell wenig. Der typische Ausfallmodus ist Thrashing im
  Squashfs-Page-Cache: das sind *saubere, dateigestützte* Seiten, die verworfen und neu
  dekomprimiert werden. Swap fasst anonyme Seiten an, nicht diese. Kosten: CPU auf
  einem 560-MHz-MIPS.
* **Weboberfläche weglassen** spart 76 KiB Flash und einen ruhenden uhttpd.

## 8. Fazit

**Gluon 2023.2.x auf 4/32: nein.** Nicht aus Mangel an Mühe, sondern weil der Kernel
seit 2018 den Platz aufgebraucht hat, den der Weimarer Maßnahmenkatalog damals noch
freiräumen konnte. Der Fehlbetrag ist rund zehnmal so groß wie alles, was das Streichen
von Statusseite, Config-Mode und uhttpd einbringt.

**Empfehlung:** den 2021.1.2-Zweig als das behandeln, was er ist — die Endstation für
diese 235 Knoten. Wenn er ohnehin noch einmal gebaut wird, dann mit geprüfter
Blockgröße nach Kapitel 7. Das ist die einzige Stellschraube in dieser Sache, die
messbar etwas bewegt.

## 9. Quellen

* Vortrag: [Fight for the bytes! Fun with Four Megabytes Flash](https://media.ccc.de/v/35c3oio-73-fight-for-the-bytes-fun-with-four-megabytes-flash),
  mt (weimarnetz.de), 35C3 OIO 2018 — [Ankündigung](https://pretalx.35c3oio.freifunk.space/35c3oio/talk/W9RHXR/),
  [Folien (PDF)](https://pretalx.35c3oio.freifunk.space/media/freifunk-4mb.pdf)
* [We have tons of 4MB/32MB memory devices](https://forum.freifunk.net/t/20898) — Freifunk-Forum, 2019
* [TP-Link WR841 – Relikt und Zukunft](https://forum.freifunk.net/t/22798) — Freifunk-Forum, 2021
* [Ultimate Guide for 4MB flash devices – Expert only](https://forum.openwrt.org/t/ultimate-guide-for-4mb-flash-devices-expert-only/81860) — OpenWrt-Forum, 2020–2024
* [OpenWrt: build image for devices with only 4MB flash](https://openwrt.org/faq/build_image_for_devices_with_only_4mb_flash)
* [OpenWrt: Saving space](https://openwrt.org/docs/guide-user/additional-software/saving_space)
* c't „Organspende: TP-Link WR841N: RAM und Flash aufrüsten" — siehe [Forumsthread](https://forum.freifunk.net/t/20724)
* Kernel-LTO: [LWN-Serie von Nicolas Pitre](https://lwn.net/Articles/744507/)
