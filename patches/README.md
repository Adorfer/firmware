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
machen weiter. Scheitert einer, brechen sie mit Fehler ab.

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
| `config-mode/` | Config-Mode: Wizard, Outdoor-Schalter |
| `setup-mode/` | Setup-Mode: DNS-Namen, Portal-Erkennung, Setup-WLAN |
| `build/` | Gluon-Makefile und Patches für externe Module (packages/gluon, ffac) |
| `parked/` | derzeit nicht angewendet (nicht in `prepare.sh`) |

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
| `lowmem/sysctl-no-watermark-boost-64mb.sh` | post-update | kein Watermark-Boost auf 64-MB-Geräten |
| `bugfixes/sysctl-firmware-no-sysfs-fallback.sh` | post-update | kein sysfs-Fallback für fehlende Firmware (60 s Boot-Stillstand) |
| `status-page/statuspage-moredetails.sh` | post-update | Statusseite: weitere MACs und Gluon-Version |
| `status-page/statuspage-ssid.sh` | post-update | Statusseite: SSID, HT-Modus und ssid-changer |
| `status-page/statuspage-hwdetails.sh` | post-update | Statusseite: CPU-Typ, Kernzahl und BIOS |
| `status-page/statuspage-ethlinks.sh` | post-update | Statusseite: Ethernet-Geschwindigkeit je Port |
| `status-page/statuspage-ssidchanger-zaehler.sh` | post-update | Statusseite: Zähler des ssid-changer seit Boot |
| `status-page/statuspage-respondd.sh` | post-update | Statusseite: Werte aus neanderfunk-respondd, live, inkl. Temperatur |
| `status-page/web-static-version.sh` | post-update | Statusseite und Config-Mode: CSS/JS mit Versionsanhang gegen den Browser-Cache |
| `config-mode/wizard-save-only.sh` | post-update | Wizard mit „Speichern“ ohne Neustart, Warnung beim Verlassen |
| `config-mode/wizard-save-lock.sh` | post-update | nur ein „Speichern & Neustarten“ gleichzeitig |
| `setup-mode/setup-mode-hostnames.sh` | post-update | `gluon.setup` und `setup.gluon` per DNS auf 192.168.1.1 |
| `setup-mode/setup-mode-captive.sh` | post-update | Portal-Erkennung der Clients führt auf die Setup-Seite |
| `setup-mode/setup-mode-wifi.sh` | post-update | dnsmasq an br-setup, Portal-Umleitung (für neanderfunk-setup-wifi) |
| `config-mode/outdoor-schalter.sh` | post-update | Outdoor-Schalter unabhängig von preserve_channels |
| `lowmem/state-check-shell.sh` | post-update | gluon-state-check als Shell statt Lua |
| `lowmem/tunneldigger-watchdog-shell.sh` | post-update | tunneldigger-watchdog als Shell statt Lua |
| `parked/squashfs-blocksize-per-device.sh` | – | squashfs-Blockgröße je Gerät (Testaufbau, nicht aktiv) |

## Abhängigkeiten

* **`status-page/`** ist eine Kette auf dieselbe Datei: `moredetails` →
  `ssid` → `hwdetails` → `ethlinks` → `ssidchanger-zaehler` → `respondd` →
  `web-static-version`. Nur in dieser Reihenfolge oder als Ganzes übernehmen.
  `statuspage-respondd` braucht das Paket `neanderfunk-respondd` aus
  [Neanderfunk/packages](https://github.com/Neanderfunk/packages); ohne es
  bleiben die betreffenden Zeilen leer.
* **`setup-mode/`**: `setup-mode-captive` baut auf `setup-mode-hostnames` auf,
  `setup-mode-wifi` auf beiden; `setup-mode-wifi` ist nur mit dem Paket
  `neanderfunk-setup-wifi` sinnvoll.
* **`config-mode/`**: `wizard-save-lock` setzt `wizard-save-only` voraus.
* **pre-update**-Skripte legen Dateien unter `gluon/patches/…` ab; sie wirken
  nur, wenn danach `make update` läuft.
* Die übrigen Skripte sind voneinander unabhängig.
