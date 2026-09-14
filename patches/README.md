# patches/ – unsere Änderungen an Gluon und OpenWrt

*Patches for Gluon v2023.2.x / OpenWrt 23.05 used by Freifunk Neanderland,
grouped by topic. Every group directory is self-contained: script plus its
patch files; all scripts share `lib-patch.sh` one level up.*

Angewendet werden die Patches von `templates/common/prepare.sh`, in zwei
Phasen und in fester Reihenfolge: **pre-update** vor Gluons `make update`
(legt Dateien ab, die `make update` auf die Module anwendet) und
**post-update** danach. Die Reihenfolge steht nur in `prepare.sh`; die
Gruppen hier sind reine Ordnung für Leser.

## Einzelne Patches übernehmen

Jede Gruppe ist in sich geschlossen: Skript und Patchdateien liegen im selben
Verzeichnis, gemeinsam genutzt wird nur `lib-patch.sh`. Zum Übernehmen:

1. die gewünschte Gruppe (oder einzelne Skripte samt ihren Patchdateien) und
   `lib-patch.sh` kopieren, Struktur `patches/<gruppe>/…` und
   `patches/lib-patch.sh` beibehalten;
2. das Skript aus dem Gluon-Verzeichnis aufrufen, z. B.
   `cd gluon && ../patches/kernel/ag71xx-rx-ring-no-bug.sh`;
3. die Phase beachten (Tabelle). Abhängigkeiten stehen unten.

Die Skripte sind idempotent: Ist ein Patch schon drin, melden sie das und
machen weiter. Scheitert einer, brechen sie mit Fehler ab. Ausnahme: Die
`status-page/`-Kette läuft nur auf einem frischen Baum durch. Ein zweiter Lauf
bricht bei `statuspage-hwdetails` ab, weil `statuspage-respondd` dessen Teil
umgeschrieben hat. `build.sh` setzt den Gluon-Baum vor jedem Lauf zurück, dort
fällt das nicht auf.

## Gruppen

| Gruppe | Inhalt |
| --- | --- |
| `devices/` | zusätzliche Geräte (Gluon- und OpenWrt-Seite) |
| `device-fixes/` | Korrekturen für einzelne Geräte |
| `targets/` | zusätzliche Targets aus OpenWrt, die Gluon 2023.2 nicht baut |
| `kernel/` | Kernel- und Treiber-Korrekturen |
| `lowmem/` | Entlastung für Geräte mit 64 MB RAM |
| `bugfixes/` | Fehlerbehebungen am System, unabhängig vom Gerät |
| `network/` | primäre MAC, Schnittstellen und Rollen |
| `status-page/` | erweiterte Statusseite (Kette, Reihenfolge wichtig) |
| `gluon-config-mode/` | Gluons ursprüngliche Config-Mode-Oberfläche (`gluon-config-mode-*`, `gluon-web-*`): Wizard, Outdoor-Schalter |
| `setup-mode-network/` | Netzdienste im Setup-Mode (dnsmasq, uhttpd): DNS-Namen, Portal-Erkennung, Anbindung des Setup-WLANs; wirkt per Kabel wie per WLAN |
| `build/` | Gluon-Makefile und Patches für externe Module (packages/gluon, ffac) |
| `parked/` | derzeit nicht angewendet (nicht in `prepare.sh`) |

Zur Unterscheidung: Gluons **Setup-Mode** ist die Betriebsart beim Einrichten
(eigene Netzdienste, feste Adresse 192.168.1.1), der **Config-Mode** die
Weboberfläche darin. Unsere eigene Oberfläche dafür (Theme, Sammelseite,
Setup-WLAN) steckt in Paketen des Feeds (`neanderfunk-config-mode-theme`,
`neanderfunk-setup-mode`, `neanderfunk-setup-wifi`), nicht in diesen Patches.

## Alle Skripte

| Skript | Phase | Zweck |
| --- | --- | --- |
| `build/add-gluon-package-patches.sh` | pre-update | Paketpatches für packages/gluon ablegen (opkg-Keys, Airtime-Plausibilität) |
| `devices/add-lantiq-xrx200-devices.sh` | pre-update | AVM FRITZ!Box 7430 und 3390, mit OpenWrt-Patch (ath9k-Kalibrierdaten 7430) |
| `build/add-ffac-package-patches.sh` | pre-update | Paketpatch für packages/ffac ablegen |
| `bugfixes/tunneldigger-reinit-backoff.sh` | pre-update | tunneldigger: Reinit mit Pause, kein modprobe für mesh-vpn |
| `bugfixes/fix-respondd-rsk.sh` | post-update | respondd-Listener auf den Gluon-2016.x-Wert |
| `device-fixes/mi4apatch.sh` | post-update | Mi Router 4A Gigabit sysupgrade-fähig |
| `devices/add-totolink-x5000r.sh` | post-update | Totolink X5000R |
| `devices/add-mercusys-mr90x.sh` | post-update | MERCUSYS MR90X |
| `devices/add-dlink-m30.sh` | post-update | D-Link AQUILA PRO AI M30 A1 |
| `device-fixes/fix-xiaomi-ax6s-bootflags.sh` | post-update | Xiaomi Redmi AX6S: Boot-Flags bestätigen, kein Rückfall auf Stock |
| `devices/add-nanopi-r2c.sh` | post-update | FriendlyElec NanoPi R2C |
| `devices/add-cudy-3000.sh` | post-update | Cudy-3000-Serie im Target mediatek-filogic |
| `targets/additionaltargets.sh` | post-update | zusätzliche Targets und Geräte aus OpenWrt |
| `devices/add-cellular.sh` | post-update | Mobilfunkgerät ZTE MF286R |
| `network/interface-role-migration21.sh` | post-update | Migration 2021: Schnittstellen mit Client-Netz |
| `network/interfaces-patch.sh` | post-update | primäre MACs und Schnittstellenzuordnung |
| `build/patch-gluon-makefiles.sh` | post-update | Gluon-Makefile und Paketliste |
| `lowmem/limit-wireless-buffers.sh` | post-update | WLAN-Puffer nach RAM begrenzen (Backport Gluon 8f38662f; entfällt mit 2025.1) |
| `kernel/revert-mips-tlb-uniquify.sh` | post-update | MIPS: `r4k_tlb_uniquify()` zurücknehmen (Kaltstart-Hänger 74Kc) |
| `kernel/ag71xx-rx-ring-no-bug.sh` | post-update | ag71xx: kein `BUG()` bei leerem RX-Ring (RAM-Druck) |
| `kernel/rtl8221b-skip-mmd30.sh` | post-update | beim PHY-Scan MMD 30 des RTL8221B nicht lesen; sonst ist der 2,5G-Port tot, wenn beim Booten ein Kabel steckt (Cudy TR3000/WR3000H; Backport OpenWrt 88dcd8c) |
| `kernel/mt7530-phy-disable-eee.sh` | post-update | EEE am MT7530-PHY aus (Switch des MT7621): sonst Link-Schleifen an 2-paarigen Kabeln und instabile 100-Mbit-Links; Nachbau OpenWrt PR #25058 für 5.15, mit Neuaushandlung |
| `lowmem/sysctl-no-watermark-boost-64mb.sh` | post-update | kein Watermark-Boost auf 64-MB-Geräten |
| `bugfixes/sysctl-firmware-no-sysfs-fallback.sh` | post-update | kein sysfs-Fallback für fehlende Firmware (60 s Boot-Stillstand) |
| `lowmem/sysctl-64m-min-free.sh` | post-update | `vm.min_free_kbytes=2048` und kleinere Fragmentpuffer auf 64-MB-Geräten (Backport Gluon a505f767 + c6ac8914; entfällt, sobald Gluon es mitbringt) |
| `status-page/statuspage-moredetails.sh` | post-update | Statusseite: weitere MACs und Gluon-Version |
| `status-page/statuspage-ssid.sh` | post-update | Statusseite: SSID, HT-Modus und ssid-changer |
| `status-page/statuspage-hwdetails.sh` | post-update | Statusseite: CPU-Typ, Kernzahl und BIOS |
| `status-page/statuspage-ethlinks.sh` | post-update | Statusseite: Ethernet-Geschwindigkeit je Port |
| `status-page/statuspage-ssidchanger-zaehler.sh` | post-update | Statusseite: Zähler des ssid-changer seit Boot |
| `status-page/statuspage-respondd.sh` | post-update | Statusseite: Werte aus neanderfunk-respondd, live, inkl. Temperatur |
| `status-page/web-static-version.sh` | post-update | Statusseite und Config-Mode: CSS/JS mit Versionsanhang gegen den Browser-Cache |
| `gluon-config-mode/wizard-save-only.sh` | post-update | Wizard mit „Speichern“ ohne Neustart, Warnung beim Verlassen |
| `gluon-config-mode/wizard-save-lock.sh` | post-update | nur ein „Speichern & Neustarten“ gleichzeitig |
| `setup-mode-network/setup-mode-hostnames.sh` | post-update | `gluon.setup` und `setup.gluon` per DNS auf 192.168.1.1 |
| `setup-mode-network/setup-mode-captive.sh` | post-update | Portal-Erkennung der Clients führt auf die Setup-Seite |
| `setup-mode-network/setup-mode-wifi.sh` | post-update | dnsmasq an br-setup, Portal-Umleitung (für neanderfunk-setup-wifi) |
| `gluon-config-mode/outdoor-schalter.sh` | post-update | Outdoor-Schalter unabhängig von preserve_channels |
| `lowmem/state-check-shell.sh` | post-update | gluon-state-check als Shell statt Lua |
| `lowmem/tunneldigger-watchdog-shell.sh` | post-update | tunneldigger-watchdog als Shell statt Lua |
| `parked/squashfs-blocksize-per-device.sh` | – | squashfs-Blockgröße je Gerät (Testaufbau, nicht aktiv) |
| `parked/cudy-rtl8221b-irq-parent.sh` | – | TR3000/M3000: `interrupt-parent = <&pio>` für den 2,5G-PHY (Backport OpenWrt 82b69df); geparkt bis zur Bestätigung des MMD-30-Hacks, siehe Patchkopf |

## Abhängigkeiten

* **`status-page/`** ist eine Kette auf dieselbe Datei: `moredetails` →
  `ssid` → `hwdetails` → `ethlinks` → `ssidchanger-zaehler` → `respondd` →
  `web-static-version`. Nur in dieser Reihenfolge oder als Ganzes übernehmen.
  `statuspage-respondd` braucht das Paket `neanderfunk-respondd` aus
  [Neanderfunk/packages](https://github.com/Neanderfunk/packages); ohne es
  bleiben die betreffenden Zeilen leer.
* **`setup-mode-network/`**: `setup-mode-captive` baut auf `setup-mode-hostnames` auf,
  `setup-mode-wifi` auf beiden; `setup-mode-wifi` ist nur mit dem Paket
  `neanderfunk-setup-wifi` sinnvoll.
* **`gluon-config-mode/`**: `wizard-save-lock` setzt `wizard-save-only` voraus.
* **pre-update**-Skripte legen Dateien unter `gluon/patches/…` ab; sie wirken
  nur, wenn danach `make update` läuft.
* Die übrigen Skripte sind voneinander unabhängig.
