# Targets und Geräte beim Umstieg 2023.2.x → 2025.1.x

Bestandsaufnahme, Stand 2026-09-05. **Nur Analyse, nichts umgesetzt.**

## Kurzfassung

| | |
|---|---|
| Targets in `targets.conf` | 31 (8 aktiv, 23 mit `-` deaktiviert) |
| Von euren Patches ergänzte Geräte | **34** |
| davon in Gluon 2025.1 bereits upstream | **19** — Patch entbehrlich |
| davon nachzuziehen | **15** — aber **alle 15 in OpenWrt 24.10 vorhanden**, also je eine `device()`-Zeile |
| Targets, die entfallen | **1** (`realtek-rtl838x`) |
| Geräte, die entfallen | **2** |
| Als „deprecated" markierte Geräte | **0** in beiden Zweigen |

Die Sorge „einige Targets fallen weg, weil sie nicht mehr in den Speicher passen"
bestätigt sich für diesen Schritt **nicht**. Gluon kennt zwar `GLUON_DEPRECATED`
(eure `site.mk` setzt `full`), aber weder 2023.2.x noch 2025.1.x markieren auch nur
ein einziges Gerät als deprecated. Der große Flash-Kahlschlag lag vor 2023.2.

Der Aufwand liegt woanders: **nicht** bei den Geräten, sondern bei den zwei
OpenWrt-seitigen Kernel-Patches und beim Target-Rename `ipq807x-generic` →
`qualcommax-ipq807x`.

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

### 4.1 zbit-Flash-Patch — Kernel 5.15 → 6.6

`add-totolink-x5000r.sh` legt `412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch`
in **`target/linux/ramips/patches-5.15/`** ab. In OpenWrt 24.10 heißt das Verzeichnis
`patches-6.6`. Der Patch fasst `drivers/mtd/spi-nor/{core.c,core.h,Makefile}` an und
legt `zbit.c` an — zwischen 5.15 und 6.6 hat sich die spi-nor-API geändert, ein
reines Umkopieren wird nicht genügen.

**Offene Frage:** Der Totolink X5000R ist in Gluon 2025.1 upstream, und OpenWrt 24.10
enthält **keinen** zbit-Support. Entweder brauchen nur bestimmte Hardware-Revisionen
den Chip, oder das Gerät läuft dort ohne. Vor dem Rebase klären — womöglich entfällt
der Patch ersatzlos.

Nebenbei: das Skript referenziert auch `patches-5.10`, ein Überbleibsel aus
noch älteren Zeiten.

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

1. `prepare.sh` laut Kapitel 4.3 laut machen — **vor** allem anderen, sonst ist jeder
   Migrationsversuch blind.
2. Die acht entfallenden Patches entfernen, die sechs schrumpfenden kürzen.
3. `targets.conf`: `realtek-rtl838x` streichen, `ipq807x-generic` in
   `qualcommax-ipq807x` umbenennen.
4. Die 15 fehlenden Geräte als je eine `device()`-Zeile nachziehen.
5. zbit-Frage klären (4.1), `mi4ag-migration.patch` prüfen (4.2).
6. Erst dann bauen.

Nicht Teil dieser Aufstellung, aber ebenfalls offen: Tunneldigger aus
`community-packages`, die Site-Feeds ohne 2025.1-Branch, die opkg-URLs auf `23.05.5`
in der `site.conf` sowie die Verhaltens-Patches (`010-primary-mac`, `020-interfaces`,
`interface-role-migration21`, `fix-respondd-rsk`, `gluon-makefile`, `gluon-packages`).
