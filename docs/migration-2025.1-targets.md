# Targets und Geräte beim Umstieg 2023.2.x → 2025.1.x

Bestandsaufnahme, Stand 2026-09-05. **Nur Analyse, nichts umgesetzt.**

> **Lies zuerst Kapitel 0.** Der maßgebliche Vergleich sind die Modellnamen im
> Autoupdater-Manifest, nicht die Target- oder Boardnamen. Ändert sich der Name,
> findet ein Bestandsknoten sein Update nicht mehr.

## Umfang

Betrachtet wird, was bei der Migration **Probleme machen kann**. Zwei Gruppen sind
darum ausdrücklich ausgenommen:

* **Geräte, die nicht im Feld sind.** Was nirgends läuft, kann auch keinen Update-Pfad
  verlieren. Solche Geräte tauchen hier nur nachrichtlich auf, damit klar ist, was
  beim Wegfall eines Patches an Baubarkeit verloren ginge.
* **Die Sackgassen-Geräte auf v2021.1.2.** Rund 231 Knoten der 4/32-Klasse
  (TP-Link WR841N/ND v8–v11 und Verwandte) hängen dort fest, weil Gluon diese Hardware
  **schon vor 2023.2** fallen gelassen hat — in 2023.2 existiert nur noch
  `tp-link-tl-wr841n-v13`. Das ist mit einem Versionswechsel nicht lösbar und hat mit
  2025.1 nichts zu tun. Eigenes Thema.

## 0. Manifest-Namen — der entscheidende Vergleich

### Warum dieser Name zählt

`scripts/generate_manifest.lua` schreibt je Sysupgrade-Image die Zeile

```
<model> <release> <sha256> <größe> <dateiname>
```

`model` ist das **erste Argument von `device(image, board, options)`**, also der
Gluon-Imagename — nicht der OpenWrt-Boardname. Zusätzlich entsteht je eine Zeile für
jeden Eintrag in `options.aliases` und `options.manifest_aliases`; letzteres ist genau
der Mechanismus, mit dem Gluon Umbenennungen abfedert.

Der Knoten meldet denselben Namen. Auf dem Testknoten COVR-X1860 live geprüft:

```
image_name: d-link-covr-x1860-a1        (Board wäre: dlink,covr-x1860-a1)
```

Ein Knoten sucht sich also im Manifest über den Namen, der in **sein** Image
einkompiliert wurde. Fehlt dieser Name im neuen Manifest, bekommt er keine Updates
mehr — er fällt still aus dem Autoupdater.

### Datengrundlage

Verglichen wurde das **echte Manifest eures Baus**
(`images-1788320276`, Domain 05_mon, broken, 253 Modellnamen) gegen die vollständige
Namensmenge von Gluon 2025.1 (363 Namen aus 328 Geräten, inklusive aller Aliase).

Nebenbefund: Gluon hat kräftig ausgemistet — 2023.2.x führt 81 Aliase, 2025.1.x nur
noch 35.

### Ergebnis: 61 Namen aus eurem Manifest fehlen in 2025.1

**a) 12 Namen — kommen mit dem Forward-Port zurück**

Eure eigenen Patch-Geräte und die von euch vergebenen Aliase. Da ihr die Namen selbst
bestimmt, sind sie nach dem Nachziehen unverändert wieder da:

`cudy-ap3000-v1`, `cudy-m1800`, `cudy-tr3000-256mb-v1`, `tp-link-eap225-wall-v2`,
`zte-mf286r`, `zyxel-nbg6616`, `mikrotik-routerboard-750gr3`,
`mikrotik-routerboard-mapl-2nd`, `mikrotik-routerboard-wap-g-5hact2hnd`
sowie deren Aliase `mikrotik-routerboard-hex-v3`, `mikrotik-routerboard-map-lite`,
`mikrotik-routerboard-wap-ac-t2`.

**b) 1 Name — echter Konflikt, Handlungsbedarf**

| | |
|---|---|
| euer Name | `cudy-ap3000outdoor-v1` |
| Gluon 2025.1 | `cudy-ap3000-outdoor-v1` |

Gleiches Board (`cudy_ap3000outdoor-v1`), abweichender Imagename, **kein Alias**.
Übernehmt ihr die Upstream-Definition, verlieren bereits ausgelieferte Cudy AP3000
Outdoor ihren Update-Pfad.

Abhilfe: `manifest_aliases = {'cudy-ap3000outdoor-v1'}` an der Upstream-Definition
ergänzen. Besser upstream einreichen als lokal patchen — andere Communities mit
demselben Gerät haben dasselbe Problem.

**c) 48 Namen — von Gluon aufgegebene Legacy-Aliase**

Alte Schreibweisen, die Gluon 2023.2 noch als `manifest_aliases` mitgeschleppt hat und
2025.1 nicht mehr führt: die ganze `openmesh-*`-Familie, `tp-link-cpe210-v1.0` und
Verwandte, `tp-link-tl-wr1043n-nd-v*`, `ubnt-erx`, `ubnt-erx-sfp`, `x86-kvm`,
`x86-xen_domu`, `zbt-wg3526*`, `netgear-wndr3700v2`, `d-link-dir-505-rev-a*` und
weitere.

**Diese Namen betreffen nur Knoten, die noch mit sehr alter Firmware laufen.** Ein
Knoten, der seit 2023.2 mindestens einmal aktualisiert wurde, meldet den heutigen
Primärnamen — und der existiert in 2025.1 weiterhin. Geprüft: es gibt **keine einzige**
Upstream-Umbenennung zwischen 2023.2 und 2025.1, bei der der Primärname wechselt, ohne
dass ein Alias den alten abfängt.

Diese Kategorie ist damit kein Migrationsblocker, aber ein Restrisiko für
Karteileichen. Gluon 2025.1 unterstützt ohnehin nur Upgrades ab v2022.1.

### Abgleich mit dem Feld — und damit die Entwarnung

Datenquelle: `https://map.eulenfunk.de/data/nodes.json`, 1199 Knoten, davon 1115 online
(Stand 2026-09-05). `https://map.ffdus.de/data/nodes.json` liefert dagegen nur
`{"version":null,"nodes":null}` und ist unbrauchbar.

**835 Knoten melden ein `image_name`** — durchweg die auf v2023.2.5. Sie verteilen sich
auf **67 verschiedene Namen**, und davon fehlt in Gluon 2025.1:

> **kein einziger.**

Sieben der 67 stammen aus euren Patches, und alle sieben sind in 2025.1 bereits
upstream:

| Imagename | Knoten |
|---|---|
| `totolink-x5000r` | 13 |
| `cudy-wr3000e-v1` | 6 |
| `cudy-wr3000h-v1` | 4 |
| `tp-link-archer-ax23-v1` | 2 |
| `cudy-wr3000s-v1` | 1 |
| `mercusys-mr90x-v1` | 1 |
| `cudy-tr3000-v1` | 1 |

**Für ausgeliefertes Gerät ist also kein einziger Forward-Port nötig.** Die 15 Geräte
aus Kapitel 2.2 betreffen ausnahmslos Hardware, die ihr derzeit nicht im Feld habt.

Auch der Namenskonflikt aus (b) entschärft sich: `cudy-ap3000outdoor-v1` kommt im Feld
**nicht** vor. Er ist ein Risiko für die Zukunft — solltet ihr AP3000 Outdoor noch unter
2023.2 ausrollen, entsteht das Problem. Vorher migrieren, oder gleich den
Upstream-Namen verwenden.

### Die restlichen 364 Knoten — außerhalb des Umfangs

Sie melden kein `image_name`. 76 davon sind gar keine Gluon-Knoten (Basis `Ubuntu`,
Modell `KVM VirtualMachine` — Gateways). Die übrigen 279 laufen auf v2021.1.2 oder
älter, davon 231 auf der 4/32-Klasse. Siehe **Umfang** oben: nicht lösbar, nicht Teil
dieser Betrachtung.

Damit erledigt sich auch Kategorie (c): die 48 aufgegebenen Legacy-Aliase betreffen
ausschließlich Knoten aus dieser Gruppe.

## Kurzfassung

| | |
|---|---|
| Targets in `targets.conf` | 31 (8 aktiv, 23 mit `-` deaktiviert) |
| Von euren Patches ergänzte Geräte | **34** |
| davon in Gluon 2025.1 bereits upstream | **19** — Patch entbehrlich |
| davon nachzuziehen | **15** — aber **alle 15 in OpenWrt 24.10 vorhanden**, also je eine `device()`-Zeile |
| **Im Feld tatsächlich betroffen** | **0 Geräte** — alle 67 Imagenamen der 835 Knoten auf v2023.2.5 kennt 2025.1 |
| Targets, die entfallen | **1** (`realtek-rtl838x`) |
| Geräte, die entfallen | **2** |
| Als „deprecated" markierte Geräte | **0** in beiden Zweigen |

Die Sorge „einige Targets fallen weg, weil sie nicht mehr in den Speicher passen"
bestätigt sich für diesen Schritt **nicht**. Gluon kennt zwar `GLUON_DEPRECATED`
(eure `site.mk` setzt `full`), aber weder 2023.2.x noch 2025.1.x markieren auch nur
ein einziges Gerät als deprecated. Der große Flash-Kahlschlag lag vor 2023.2.

Der Aufwand liegt woanders: beim Target-Rename `ipq807x-generic` →
`qualcommax-ipq807x` und bei `mi4ag-migration.patch`. Der zbit-Flash-Patch, zunächst
als größte Baustelle eingeschätzt, ist unter Kernel 6.6 aller Voraussicht nach
entbehrlich — siehe 4.1.

## Methode

Verglichen wurden die Git-Stände `v2023.2.x` (`cd304be`) und `v2025.1.x` (`0ad3ad5`)
von `freifunk-gluon/gluon`, dazu OpenWrt am von Gluon 2025.1 gepinnten Commit
`a1ea57bd` (24.10, Kernel 6.6).

Geräte wurden über die `device('name', 'board')`-Einträge in `targets/*` erfasst und
über den **OpenWrt-Boardnamen** abgeglichen, nicht über den Gluon-Namen — der kann
sich unterscheiden. Vollzähligkeit geprüft: 268 von 268 bzw. 328 von 328
`device(`-Zeilen erfasst.

Für die 15 fehlenden Geräte wurde gegen **alle** Image-Makefiles des jeweiligen
OpenWrt-Targets geprüft, nicht nur gegen `generic.mk`. Das war nötig: TP-Link-Geräte
liegen in `generic-tp-link.mk`, und eine erste, unvollständige Prüfung hätte zwei
Geräte fälschlich als „in OpenWrt nicht vorhanden" gemeldet.

## 1. Target-Ebene

Von euren 31 Targets existieren 29 unverändert in 2025.1. Drei Sonderfälle:

| Target | Befund | Zu tun |
|---|---|---|
| `realtek-rtl838x` | in 2025.1 **entfallen** | Zeile aus `targets.conf` streichen. Bei euch ohnehin deaktiviert; einziges Gerät war die D-Link DGS-1210-10P |
| `ipq40xx-chromium` | von euch gepatcht, jetzt **upstream** | Patch entfernen, Target bleibt in `targets.conf` |
| `ipq807x-generic` | **umbenannt** zu `qualcommax-ipq807x` | In `targets.conf` umbenennen, Patch entfernen |

Neu in 2025.1 und für euch bisher ohne Bedeutung: `kirkwood-generic`,
`lantiq-xrx200_legacy`, `mvebu-cortexa53`.

## 2. Geräte-Ebene

### 2.1 Bereits upstream — 19 Geräte, Patches entbehrlich

| Target | Gerät |
|---|---|
| ath79-generic | tp-link-eap225-outdoor-v3 |
| ipq40xx-chromium | google-wifi-gale |
| ipq40xx-generic | linksys-mr8300-dallas |
| qualcommax-ipq807x | xiaomi-ax3600 *(Target umbenannt)* |
| lantiq-xrx200 | avm-fritz-box-7430 |
| mediatek-filogic | cudy-ap3000outdoor-v1, cudy-m3000-v1, cudy-re3000-v1, cudy-tr3000-v1, cudy-wr3000e-v1, cudy-wr3000h-v1, cudy-wr3000s-v1, mercusys-mr90x-v1 |
| mediatek-mt7622 | netgear-wax206, ubiquiti-unifi-6-lr-v2, ubiquiti-unifi-6-lr-v3 |
| ramips-mt7621 | totolink-x5000r, tp-link-archer-ax23-v1, ubiquiti-unifi-nanohd |

### 2.2 Nachzuziehen — 15 Geräte, alle in OpenWrt 24.10 vorhanden

| Target | Gerät | OpenWrt-Board |
|---|---|---|
| ath79-generic | tp-link-eap225-wall-v2 | `tplink_eap225-wall-v2` |
| ath79-generic | zyxel-nbg6616 | `zyxel_nbg6616` |
| ath79-mikrotik | mikrotik-routerboard-mapl-2nd | `mikrotik_routerboard-mapl-2nd` |
| ath79-mikrotik | mikrotik-routerboard-wap-g-5hact2hnd | `mikrotik_routerboard-wap-g-5hact2hnd` |
| ath79-nand | zte-mf286r | `zte_mf286r` |
| ipq40xx-generic | avm-fritz-repeater-3000 | `avm_fritzrepeater-3000` |
| ipq40xx-generic | linksys-ea8300-dallas | `linksys_ea8300` |
| ipq40xx-mikrotik | mikrotik-wap-ac | `mikrotik_wap-ac` |
| qualcommax-ipq807x | netgear-wax218 | `netgear_wax218` |
| lantiq-xrx200 | avm-fritz-box-3390 | `avm_fritz3390` |
| mediatek-filogic | cudy-ap3000-v1 | `cudy_ap3000-v1` |
| mediatek-filogic | cudy-tr3000-256mb-v1 | `cudy_tr3000-256mb-v1` |
| ramips-mt7621 | cudy-m1800 | `cudy_m1800` |
| ramips-mt7621 | mikrotik-routerboard-750gr3 | `mikrotik_routerboard-750gr3` |
| rockchip-armv8 | friendlyelec-nanopi-r2c | `friendlyarm_nanopi-r2c` |

Weil alle Boards in OpenWrt existieren, ist der Forward-Port jeweils **eine Zeile**
in der Gluon-Target-Datei. Kein Bedarf an DTS-Dateien oder Kernel-Arbeit.

Auffällig: Gluon 2025.1 kennt `cudy-ap3000outdoor-v1`, aber nicht `cudy-ap3000-v1`,
obwohl beide DTS in OpenWrt liegen. Sieht nach Versehen upstream aus — wäre ein
Kandidat für einen Beitrag zurück an Gluon statt für einen lokalen Patch.

### 2.3 Was entfällt

Nur zwei Geräte verschwinden zwischen 2023.2.x und 2025.1.x:

* `ubiquiti-nanobeam-m5-xw` (ath79-generic)
* `d-link_dgs-1210-10p` (realtek-rtl838x, mit dem ganzen Target)

Beide sind bei euch nicht im Einsatz, soweit aus `targets.conf` ersichtlich —
`realtek-rtl838x` ist deaktiviert.

## 3. Patch für Patch

### Entfallen vollständig

| Patch | Grund |
|---|---|
| `targets-mk.patch` | beide Registrierungen upstream (`ipq40xx-chromium`, `qualcommax-ipq807x`) |
| `targets-ipq40xx-chromium.patch` | Target und Gerät upstream |
| `targets-mediatek-mt7622.patch` | alle drei Geräte upstream |
| `add-cudy-3000-openwrt.patch` | alle neun DTS in OpenWrt 24.10 vorhanden (dort inzwischen 14 Cudy-DTS) |
| `add-cudy-3000-singleeth-openwrt.patch` | alle sieben `cudy,*`-Einträge in `05_set_preinit_iface` upstream |
| `add-mercusys-mr90x-gluon.patch` | Gerät upstream |
| `targets-ipq40xx-mirotik.patch` | ungenutzte Dublette mit Tippfehler im Namen; `additionaltargets.sh` ruft die korrekt geschriebene Datei auf |
| `999-silence-missing-rate.patch` | entspricht Gluons eigenem `0005-mac80211-silence-warning-for-missing-rate-information.patch` (bei euch ohnehin nicht aktiv) |

### Schrumpfen auf die Restgeräte

| Patch | vorher | bleibt |
|---|---|---|
| `targets-ath79-generic.patch` | 3 | 2 (eap225-wall-v2, zyxel-nbg6616) |
| `targets-ipq40xx-generic.patch` | 3 | 2 (fritz-repeater-3000, ea8300-dallas) |
| `targets-ramips-mt7621.patch` | 4 | 2 (cudy-m1800, rb750gr3) |
| `add-cudy-3000-gluon.patch` | 9 | 2 (ap3000-v1, tr3000-256mb-v1) |
| `targets-lantiq-xrx200-devices.patch` | 2 | 1 (fritz-box-3390) |
| `targets-ipq807x-generic.patch` | 2 | 1 (wax218), **auf `qualcommax-ipq807x` umschreiben** |

### Bleiben unverändert nötig

`targets-ath79-mikrotik.patch` (2 Geräte), `targets-ath79-nand.patch` (zte-mf286r),
`targets-ipq40xx-mikrotik.patch` (wap-ac), `add-nanopi-r2c` (nanopi-r2c).

`targets-ipq40xx-mikrotik.patch` ändert zusätzlich `platform.lua`: es trägt
`mikrotik,routerboard-wap-g-5hact2hnd` und `mikrotik,wap-ac` in die Outdoor-Geräteliste
ein. Beide fehlen in 2025.1 weiterhin, der Teil muss also mit. `cudy,ap3000outdoor-v1`
steht dort inzwischen upstream.

## 4. Die eigentlichen Baustellen

### 4.1 zbit-Flash-Patch — mit hoher Wahrscheinlichkeit entbehrlich

`add-totolink-x5000r.sh` legt `412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch`
in `target/linux/ramips/patches-5.15/` ab. Er stammt von Daniel Palmer, wurde
2021-09-18 an linux-mtd geschickt und ergaenzt die JEDEC-ID des Zbit ZB25VQ128
(`5e 40 18`), den Totolink ab Baujahr 2022 verbaut.

**Recherchiert am 2026-09-05:**

* Der Patch ist **nie in den Linux-Kernel gelangt** — weder in 6.6 noch in der
  aktuellen Mainline gibt es `drivers/mtd/spi-nor/zbit.c`, und weder `core.c` noch
  `core.h` erwaehnen `zbit` oder `zb25`.
* In OpenWrt lief er als PR #12396 („ramips: add linux 5.15 and 5.10 support for Zbits
  ZB25VQ128 SPI-NOR on Totolink X5000R", 2023-04-14). Der PR wurde **nach einem Tag
  ohne Kommentar geschlossen**, nicht gemerged.
* Eine Fassung gegen Kernel 6.6 existiert nirgends.

**Sie wird aller Voraussicht nach auch nicht gebraucht.** Kernel 6.6 hat einen
generischen Rueckfall eingebaut, den 5.15 und 6.1 noch nicht kannten:

```c
/* Fallback to a generic flash described only by its SFDP data. */
if (!info) {
        ret = spi_nor_check_sfdp_signature(nor);
        if (!ret)
                info = &spi_nor_generic_flash;
}
```

Ist die JEDEC-ID unbekannt, aber liefert der Chip gueltige SFDP-Tabellen, laeuft er
ueber `spi-nor-generic`. Die Kernel-Doku sagt dazu: *„For flashes that define SFDP
tables, you likely won't need a flash entry at all."* Genau das Fehlen dieses Rueckfalls
machte den Patch unter 5.15 noetig.

Geprueft: `spi_nor_generic_flash` kommt in Linux 5.15 und 6.1 **nicht** vor, in 6.6
**doch**.

**Restunsicherheit:** Ob der ZB25VQ128ASIG gueltige SFDP-Tabellen liefert, liess sich
nicht belegen — nur Chips ganz ohne SFDP fallen weiterhin durch. Bei einem Baustein
dieser Generation ist SFDP praktisch Standard.

**Billig zu klaeren, noch vor der Migration.** Auf einem der 13 X5000R im Feld:

```
dmesg | grep -i spi-nor
```

Steht dort ein konkreter Chipname, ist die ID bekannt und die Frage erledigt. Steht
dort `spi-nor-generic`, greift bereits heute der SFDP-Weg. Und zeigt der Chip sich als
Winbond oder XMC statt Zbit, betrifft euch die Sache ohnehin nicht — im
OpenWrt-Forum berichtet ein Nutzer genau das fuer seine Geraete.

**Empfehlung:** den Patch beim Umstieg **ersatzlos streichen** und beim ersten Testbau
einen X5000R gegenpruefen. Ein Rebase des 5.15-Patches auf 6.6 waere ohnehin Handarbeit,
weil sich die spi-nor-API dazwischen geaendert hat.

### 4.2 `mi4ag-migration.patch`

Ändert `package/base-files/files/lib/upgrade/fwtool.sh` und
`target/linux/ramips/image/mt7621.mk`. Beide Dateien haben sich zwischen 23.05 und
24.10 bewegt; der Patch ist gegen 24.10 neu zu prüfen. Nicht analysiert, weil er die
Sysupgrade-Logik betrifft und nicht die Target-Auswahl.

### 4.3 Der `patch -R`-Mechanismus

Alle Patch-Skripte prüfen per Rückwärts-Trockenlauf, ob schon angewendet, und
schweigen bei Fehlschlag; `prepare.sh` endet mit `exit 0;`. Bei einem Sprung über
eine Hauptversion **fallen scheiternde Patches damit nicht auf**. Vor dem
Migrationsversuch sollte das `exit 0;` weichen und Patch-Fehler den Build abbrechen
lassen — sonst entsteht eine Firmware, in der still die Hälfte der Geräte fehlt.

Das neuere Muster aus `patches/statuspage-ssid.sh` und `statuspage-hwdetails.sh`
macht es richtig vor: gequotete Pfade, Vorabprüfungen, `patch -f`, geprüftes Ergebnis
mit Exit-Code.

## 5. Vorschlag zur Reihenfolge

Der Feldabgleich in Kapitel 0 hat den Pflichtteil klein gemacht.

**Pflicht**

1. `prepare.sh` laut Kapitel 4.3 laut machen — **vor** allem anderen, sonst ist jeder
   Migrationsversuch blind.
2. Die acht entfallenden Patches entfernen, die sechs schrumpfenden kürzen.
3. `targets.conf`: `realtek-rtl838x` streichen, `ipq807x-generic` in
   `qualcommax-ipq807x` umbenennen.
4. zbit-Patch ersatzlos streichen (4.1) und beim ersten Testbau einen der 13 X5000R
   gegenprüfen. `mi4ag-migration.patch` prüfen (4.2).
5. Bauen. Danach das erzeugte Manifest gegen das alte diffen: jeder Name, der
   verschwindet, ist ein Gerät ohne Update-Pfad.

**Nach Bedarf, kein Migrationsblocker**

6. Von den 15 Geräten aus Kapitel 2.2 nur das nachziehen, was ihr tatsächlich ausrollen
   wollt — im Feld ist derzeit keines davon. Dann aber **mit den bisherigen Imagenamen
   und Aliasen**.
7. `manifest_aliases = {'cudy-ap3000outdoor-v1'}` nur nötig, falls vor der Migration
   noch AP3000 Outdoor unter 2023.2 ausgerollt werden. Sonst gleich den
   Upstream-Namen `cudy-ap3000-outdoor-v1` übernehmen.

Die 4/32-Sackgasse taucht hier bewusst nicht auf — siehe **Umfang**.

Nicht Teil dieser Aufstellung, aber ebenfalls offen: Tunneldigger aus
`community-packages`, die Site-Feeds ohne 2025.1-Branch, die opkg-URLs auf `23.05.5`
in der `site.conf` sowie die Verhaltens-Patches (`010-primary-mac`, `020-interfaces`,
`interface-role-migration21`, `fix-respondd-rsk`, `gluon-makefile`, `gluon-packages`).
