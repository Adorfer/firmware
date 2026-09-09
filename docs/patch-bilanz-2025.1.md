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
Statuspage-Patches (Commit 75a6075), dazu `statuspage-ethlinks` (4381b89).

`fix-respondd-rsk` ist am 09.09.2026 im Feld bestaetigt: der migrierte ERX ist
mit dem neuen Image auf der Karte erschienen
(map.eulenfunk.de, Knoten f09fc20c3ddd). Der Patch war der kritischste der
ganzen Liste — ohne ihn antwortet respondd nicht auf `ff02::1`, der Sammler
sieht den Knoten nicht, und er steht als offline in der Karte, obwohl er
laeuft. Neu geschrieben zu haben heisst noch nicht, dass es traegt; jetzt ist
es gemessen.

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

Dazu kommt `erx-ka-imagename`, siehe naechster Abschnitt — der ist neu und
nicht zurueckportiert.

## Neu unter 2025.1

### erx-ka-imagename

Nicht aus 2023.2 uebernommen, sondern hier entstanden. Benennt EdgeRouter X
und X SFP auf `ubiquiti-edgerouter-x-ka` bzw. `ubiquiti-edgerouter-x-sfp-ka`
um, in zwei Baeumen synchron:

| Baum | Datei | Wirkung |
|---|---|---|
| openwrt | `target/linux/ramips/dts/mt7621_ubnt_edgerouter-x{,-sfp}.dts`, nur `model` | was der Node meldet |
| gluon | `targets/ramips-mt7621`, erstes Argument von `device()` | Manifestkey und Dateiname |

Grund ist das neue Flash-Layout. OpenWrt riegelt es ueber
`compat_version 1.0->2.0` ab, und dieser Riegel greift erst in
`sysupgrade --test`, also nach dem vollstaendigen Download; der major-Zweig
von `fwtool_check_image()` wertet `IGNORE_MINOR_COMPAT` nicht aus. Ein nicht
migrierter ERX laeuft deshalb bei jedem Cronlauf in denselben Fehlschlag und
zieht dabei rund 690 MB pro Tag (24 Laeufe x 4 Mirrors x 7,2 MB), ohne dass
das irgendwo sichtbar waere. Mit eigenem Imagenamen bricht er schon bei
`model_ok` ab.

`compatible` bleibt unangetastet, `SUPPORTED_DEVICES` kommt aus dem
Profilnamen — der Migrationsweg selbst ist davon unberuehrt.

Der Patch ist auf Zeit angelegt. Wie er wieder rausgeht, steht im Kopf von
`patches/erx-ka-imagename.sh`.

## Verhaeltnis der beiden Branches

`v2023.2.x` und `v2025.1.x` tragen an den zurueckportierten Stellen denselben
Inhalt, aber getrennte Historie — die Aenderungen sind auf beiden Seiten
einzeln entstanden, nicht gemergt. Ein spaeteres `git merge` erzeugt dort
Konflikte, obwohl inhaltlich nichts auseinandergeht. Wer zusammenfuehren will,
sollte das wissen und die betroffenen Dateien gezielt aufloesen statt sich auf
den Merge zu verlassen.

Betrifft aktuell: `fix-respondd-rsk.patch`, die vier Statuspage-Patches und
`templates/common/modules` (dort unterscheiden sich die Feed-Pins bewusst).

Hinweis aus der Paket-Session, 2026-09-09.
