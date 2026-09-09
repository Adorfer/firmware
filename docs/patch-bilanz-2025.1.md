# Unsere Patches gegen Gluon 2025.1 — Bestandsaufnahme

Stand 2026-09-09, geprueft gegen Gluon v2025.1.3 (OpenWrt 24.10, Kernel 6.6)
mit `patch --dry-run --ignore-whitespace` — also mit denselben Optionen, die
`apply_patch` in `patches/lib-patch.sh` verwendet. Ohne `--ignore-whitespace`
faellt die Bilanz zu pessimistisch aus: Gluon hat den Baum durch shellcheck
geschickt, wodurch sich Einrueckungen verschoben haben, ohne dass sich
inhaltlich etwas geaendert haette. Anlass: der erste 2025.1-Bau fuer den ERX lief ohne
unsere `patches/`, wodurch auf der Statusseite die Hardware-Angaben fehlten.

Dieser Branch (`v2025.1.x`) existiert, weil die Patches nicht auf beiden
Gluon-Staenden gleichzeitig gepflegt werden koennen.

## Zusammenfassung

| | Anzahl |
|---|---:|
| passt unveraendert | 9 |
| passt mit Versatz | 11 |
| scheitert, muss neu geschrieben werden | 12 |
| keine anwendbaren Patches (Dateien zum Ablegen) | 5 |

## Passt unveraendert

`010-primary-mac`, `ffac-packages`, `fix-respondd-rsk` (fuer 2025.1 neu
geschrieben), `gluon-packages`, `targets-ath79-mikrotik`,
`targets-ipq40xx-chromium`, `targets-ipq40xx-generic`,
`targets-ipq807x-generic`

### Sonderfall 010-primary-mac

Passt, ist aber nicht mehr unstrittig. Der Patch traegt `linksys,ea8300` und
`linksys,mr8300` in den LAN-Block von `primary_addrs` ein.

| Geraet | 2023.2 upstream | 2025.1 upstream | unser Patch |
|---|---|---|---|
| `linksys,ea8300` | fehlt | fehlt weiterhin | LAN |
| `linksys,mr8300` | fehlt | **WAN** | LAN |

Fuer `ea8300` bleibt der Patch schlicht noetig. Bei `mr8300` uebersteuern wir
Upstream: die Liste wird in der aufgefuehrten Reihenfolge abgearbeitet, und der
LAN-Block steht vor dem WAN-Block.

Das ist eine bewusste Entscheidung. Die primaere MAC bestimmt die node_id -
folgten wir Upstream, bekaemen diese Knoten bei der Migration die WAN-MAC,
erschienen auf der Karte als neue Knoten und verloeren ihre Historie. Der
Grund steht im Kopf des Patches, damit er beim naechsten Upstream-Vergleich
nicht wieder zur Diskussion steht.

## Passt mit Versatz

Laeuft durch, die Zeilennummern haben sich nur verschoben. Vor der Uebernahme
trotzdem ansehen, ob der Kontext noch dasselbe bedeutet:

`add-cudy-3000-gluon`, `add-mercusys-mr90x-gluon`, `add-totolink-x5000r`,
`gluon-makefile`, `mi4ag-migration`, `targets-ath79-generic`,
`targets-ath79-nand`,
`targets-ipq40xx-mikrotik`, `targets-ipq40xx-mirotik`,
`targets-lantiq-xrx200-devices`, `targets-mediatek-mt7622`,
`targets-ramips-mt7621`

## Scheitert — Arbeitsliste

| Patch | Baum | fehlgeschlagene Hunks |
|---|---|---:|
| `interface-role-migration21` | gluon | 3 |
| `statuspage-moredetails` | gluon | 3 |
| `statuspage-ssid` | gluon | 3 |
| `020-interfaces` | gluon | 2 |
| `add-nanopi-r2c` | gluon | 2 |
| `cellular` | gluon | 2 |
| `limit-wireless-buffers` | gluon | 2 |
| `statuspage-hwdetails` | gluon | 2 |
| `targets-mk` | gluon | 2 |
| `add-cudy-3000-openwrt` | openwrt | 2 |
| `add-cudy-3000-singleeth-openwrt` | openwrt | 2 |
| `kernelswapon-openwrt` | openwrt | 2 |

**Erledigt:** `fix-respondd-rsk` (Commit a978467) und die drei
Statuspage-Patches (Commit 75a6075).

Bei den Statuspage-Patches hat sich das Pruefen auf Redundanz gelohnt — ein
guter Teil unserer Erweiterungen ist inzwischen in Gluon angekommen, nur anders
formuliert:

| Bestandteil | Stand unter 2025.1 |
|---|---|
| SSID und HT-Modus je Radio | **vollstaendig upstream**, Patch neu belegt |
| Target/Subtarget | upstream als `target (subtarget)` |
| Gluon Version | upstream in der Firmware-Zeile als `release (base)` |
| Model mit Kernzahl | upstream vorhanden, aber ohne nil-Pruefung und ohne Singular — unsere Fassung bleibt |
| ImageName, Mesh-MAC, Tunnel-MAC, Sitecode | fehlt, bleibt bei uns |
| CPU-Modell, BIOS, RAM/Flash | fehlt, bleibt bei uns |

Die Model-Zeile behalten wir bewusst: Upstream schreibt ungeprueft
`model (n CPUs)`. Unsere Fassung faengt zwei Faelle ab — fehlt `nproc`, entfaellt
die Klammer statt `(nil CPUs)` zu zeigen, und bei einem Kern steht `1 CPU` statt
`1 CPUs`. Bei unseren vielen Einkern-ath79-Geraeten ist das die Regel, nicht die
Ausnahme.

`statuspage-ssid` zeigt jetzt stattdessen den Zustand des
neanderfunk-ssid-changer (`/tmp/ssid-changer-offline`, 0 oder 1) — eine Zeile
je Knoten hinter der Radio-Schleife, nicht je Radio, und nur wenn ueberhaupt
Radios da sind.

`mi4ag-migration` passt mit Versatz. Beim Uebernehmen gleich die ERX-Ausnahme
reparieren — sie prueft auf `ubnt-erx` statt `ubnt,edgerouter-x` und war schon
unter 23.05 wirkungslos (siehe TODO.md).

## Keine anwendbaren Patches

Diese fuenf Dateien werden per `copy_into_tree` im Baum *abgelegt*, statt auf
ihn angewendet zu werden. Ein Dry-Run sagt ueber sie nichts.

| Datei | unter 2025.1 |
|---|---|
| `412-mtd-spi-nor-add-support-for-zbit-zb25vq128` | **entbehrlich** — ab Kernel 6.6 greift der generische SFDP-Rueckfall |
| `486-02-mtd-spinand-esmt-add-support-for-F50L1G41LC` | **entbehrlich** — 24.10 bringt den Chip selbst mit (`backport-6.6/422-v6.19-…`) |
| `999-mips-tlb-r4k-no-uniquify` | **entbehrlich** — 6.6 hat den Fix, an 21 von 21 Kaltstarts gemessen |
| `999-silence-missing-rate` | **zu pruefen** — Ziel `net/mac80211/mesh_hwmp.c`, das Verzeichnis `package/kernel/mac80211/patches/subsys/` gibt es weiterhin |
| `tunneldiggergit` | **entbehrlich** — Ziel `net/tunneldigger/Makefile`; Tunneldigger kommt jetzt aus den community-packages |

Vier von fuenf erledigen sich also durch Upstream. Das ist der angenehme Teil
der Migration.

## Was der ERX-Bau davon braucht

Nichts aus der Arbeitsliste ausser den Statuspage-Patches. Der ERX ist
upstream unterstuetzt, hat kein WLAN und keine der betroffenen Eigenheiten.
Fuer die uebrigen Domains sieht das anders aus.
