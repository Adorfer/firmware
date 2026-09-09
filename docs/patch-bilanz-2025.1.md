# Unsere Patches gegen Gluon 2025.1 — Bestandsaufnahme

Stand 2026-09-09, geprueft gegen Gluon v2025.1.3 (OpenWrt 24.10, Kernel 6.6)
mit `patch --dry-run`. Anlass: der erste 2025.1-Bau fuer den ERX lief ohne
unsere `patches/`, wodurch auf der Statusseite die Hardware-Angaben fehlten.

Dieser Branch (`v2025.1.x`) existiert, weil die Patches nicht auf beiden
Gluon-Staenden gleichzeitig gepflegt werden koennen.

## Zusammenfassung

| | Anzahl |
|---|---:|
| passt unveraendert | 5 |
| passt mit Versatz | 10 |
| scheitert, muss neu geschrieben werden | 14 |
| keine anwendbaren Patches (Dateien zum Ablegen) | 5 |

## Passt unveraendert

`010-primary-mac`, `ffac-packages`, `gluon-packages`,
`targets-ath79-mikrotik`, `targets-ipq40xx-chromium`,
`targets-ipq40xx-generic`, `targets-ipq807x-generic`

## Passt mit Versatz

Laeuft durch, die Zeilennummern haben sich nur verschoben. Vor der Uebernahme
trotzdem ansehen, ob der Kontext noch dasselbe bedeutet:

`add-cudy-3000-gluon`, `add-mercusys-mr90x-gluon`, `add-totolink-x5000r`,
`gluon-makefile`, `targets-ath79-generic`, `targets-ath79-nand`,
`targets-ipq40xx-mikrotik`, `targets-ipq40xx-mirotik`,
`targets-lantiq-xrx200-devices`, `targets-mediatek-mt7622`,
`targets-ramips-mt7621`

## Scheitert — Arbeitsliste

| Patch | Baum | fehlgeschlagene Hunks |
|---|---|---:|
| `statuspage-moredetails` | gluon | 4 |
| `interface-role-migration21` | gluon | 3 |
| `statuspage-ssid` | gluon | 3 |
| `020-interfaces` | gluon | 2 |
| `add-nanopi-r2c` | gluon | 2 |
| `cellular` | gluon | 2 |
| `fix-respondd-rsk` | gluon | 2 |
| `limit-wireless-buffers` | gluon | 2 |
| `statuspage-hwdetails` | gluon | 2 |
| `targets-mk` | gluon | 2 |
| `add-cudy-3000-openwrt` | openwrt | 2 |
| `add-cudy-3000-singleeth-openwrt` | openwrt | 2 |
| `kernelswapon-openwrt` | openwrt | 2 |
| `mi4ag-migration` | openwrt | 2 |

Die drei Statuspage-Patten haben Vorrang: ohne sie fehlen auf der Statusseite
die Angaben zu RAM und Flash, und das faellt sofort auf.

Bei `mi4ag-migration` gleich die ERX-Ausnahme mit reparieren — sie prueft auf
`ubnt-erx` statt `ubnt,edgerouter-x` und war schon unter 23.05 wirkungslos
(siehe TODO.md).

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
