# mt7915 / filogic: Stand der Ermittlungen und was wir tun sollten

Untersuchung, Stand 2026-09-07. **Nur Analyse, nichts umgesetzt.**

> **Kurzfassung.** Zwei Dinge sind zu tun, beide klein:
>
> 1. **`patches/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch` löschen.**
>    Er liegt deaktiviert im Repo. Upstream wurde derselbe Ansatz aufgenommen und
>    vier Wochen später **wieder zurückgenommen**, weil er schlafende Clients nicht
>    mehr aufweckt. Einschalten wäre ein Rückschritt.
> 2. **Gluons Puffer-Deckel `8f38662f` nachziehen** — 13 Zeilen Shell, kein Treiber.
>    Wirkt allerdings nur auf unsere Geräte bis 128 MB RAM; für die filogic-Klasse
>    müsste man die Grenze selbst weiterziehen.
>
> Auf Treiberebene ist bei uns **nichts zu holen**: OpenWrt 23.05 ist auf mt76
> vom 2024-04-03 eingefroren, wir fahren bereits diesen Stand. Alles Weitere hängt
> am Sprung auf 2025.1.

## 1. Unser Ausgangspunkt

| | |
|---|---|
| OpenWrt | Zweig `openwrt-23.05`, Commit `7f61f962` |
| Kernel | 5.15.198 |
| mt76 | `PKG_SOURCE_DATE 2024-04-03`, `1e336a8582dce2ef` |
| betroffene Targets | `mediatek-filogic`, `mediatek-mt7622`, `ramips-mt7621` (mt7915e-Karten) |

Aktive Gegenmaßnahmen bei uns:

* `neanderfunk-mt7915-backlog` — liest alle zwei Minuten `iw phy <phy> get txq`,
  startet WLAN neu, wenn der Backlog über dem Schwellwert liegt. Vorgaben:
  Schwelle 50, erst ab 5 min Laufzeit prüfen, erst ab 60 min handeln,
  30 min Sperre nach einem Neustart.
* `neanderfunk-hotfix`, Check `wifi_firmware` — rebootet beim bekannten
  Firmware-Fehlerbild (seit Feed-Commit `c15c83e0`, löste `ffac-mt7915-hotfix` ab).
* Gluons eigener Patch `0007-mac80211-silence-warning-for-missing-rate-information`
  — kosmetisch, hält das Log frei.

Deaktiviert im Repo liegen:

* `mt7915-filogic-syncpowersave-patch.sh` samt Patchdatei — siehe Kapitel 3.
* `airtime-logsilience.sh` — überflüssig, Gluon liefert `0007-...` selbst.
* `add-mt7915e-try.sh` — die Patchdatei war nie im Repo.

## 2. Der Stand upstream

### 2.1 Der Power-Save-/AQL-Strang — der für uns entscheidende

Die Hardware puffert Frames für schlafende Stationen **unbegrenzt**. Bleibt eine
Station im Power-Save und bekommt weiter Daten, füllt sich die TX-Queue, AQL
gerät durcheinander, der Backlog wächst. Das ist genau das Bild, auf das unser
`neanderfunk-mt7915-backlog` reagiert.

Die Aufarbeitung in `openwrt/mt76`:

| Commit | Datum | Was |
|---|---|---|
| `be3aad4c2e10` | 2026-02-21 | David Bauer: *sync station power save state* — der Ansatz, den wir als Patchdatei liegen haben |
| `ca81c5c18ec8` | 2026-03-19 | **Revert** durch Felix Fietkau |
| `9a46d8d21d2a` | 2026-05-07 | *add PS buffering support for HW-managed TIM drivers* — neue Kerninfrastruktur |
| `9e613fb007f5` | 2026-05-07 | *mt7915: handle MCU PS sync events* — der Nachfolger, setzt auf obiger auf |
| `b0af99f238f7` | 2026-05-07 | dasselbe für mt7996 |
| `f8b59ca3be7b` | 2026-06-23 | *don't pin undrainable PS stations in the tx scheduler* — Nachbesserung |

Die Begründung des Reverts im Wortlaut:

> This causes a regression by preventing queueing of frames that would otherwise
> lead to a PS station being woken up.
> Fixes: https://github.com/openwrt/mt76/issues/1068

Issue #1068 beschreibt die Folge: Geräte im Power-Save wachen nicht mehr auf,
die Verbindung wirkt abgerissen. Gemeldet auf OpenWrt 25.12.

**Für uns heißt das: den Patch nicht einschalten.** Er ist kein "noch nicht
getesteter Kandidat", sondern ein upstream verworfener Ansatz mit bekannter
Regression.

Der Nachfolger ist nicht backportierbar. Geprüft am entpackten Quelltext unseres
mt76-Stands:

```
MT_DRV_HW_PS_BUFFERING    FEHLT
mt76_connac_ps_sync       FEHLT
MCU_EXT_EVENT_PS_SYNC     vorhanden (mt76_connac_mcu.h)
```

`9e613fb0` braucht die Kerninfrastruktur aus `9a46d8d2`, und die kam 13 Monate
nach unserem Stand. Es wären vier Commits, davon zwei im gemeinsamen Treiberkern.

### 2.2 Der MCU-Timeout-Strang — ohne Abschluss

`mt7915e: Message timeout while waiting for mcu response`
([Issue #690](https://github.com/openwrt/mt76/issues/690), offen seit 2022-08,
210 Kommentare) ist der Sammelthread für das harte Fehlerbild: WLAN unbrauchbar
bis zum Reboot, gehäuft bei 40+ Clients und langer Laufzeit. Die Diskussion
verläuft 2023 im Sand; der zuletzt vorgeschlagene SER-Recovery-Patch half dem
Melder nicht.

Das ist der Fehler, den unser `wifi_firmware`-Check per Reboot auffängt.

### 2.3 filogic im Besonderen

[Issue #922](https://github.com/openwrt/mt76/issues/922) (MT7981, seit 2024-10)
beschreibt genau unsere Chipklasse. Stand der letzten Wortmeldung (2025-09-27):

> There is no more freezing of the 5GHz WiFi. […] Sometimes the transmission
> speed is reduced, e.g. from 600 Mbit to 200 Mbit but it can be restored by
> reconnecting.

Das Einfrieren ist also behoben, der Durchsatzeinbruch nicht — und er tritt noch
im SNAPSHOT auf. In der Diskussion taucht mehrfach das Energiesparen **der
Clients** als Auslöser auf, was zum PS-Strang aus 2.1 passt.

### 2.4 Die Grenze

Ein Teil bleibt unlösbar: die WLAN-Firmware der Chips ist verschlüsselt.
Treiberseitige Patches können das Verhalten abfedern, nicht beheben.

## 3. Betrifft uns das, und gibt es Bewegung in 23.05?

Nein, und das ist die wichtigste Zahl dieser Untersuchung:

```
openwrt-23.05 (Zweigspitze heute):  mt76 2024-04-03  1e336a8582dce2ef
unser gepinnter Stand:              mt76 2024-04-03  1e336a8582dce2ef
openwrt-24.10:                      mt76 2025-11-06  eb567bc7f9b692bb
```

**OpenWrt 23.05 ist auf mt76 vom April 2024 eingefroren.** Wir fahren bereits den
letzten Stand, den diese Release-Linie hergibt. Ein Bump von OpenWrt innerhalb
23.05 bringt am Treiber nichts. Die 19 Monate Treiberarbeit stecken in 24.10 —
und damit in Gluon 2025.1.

Das schließt auch die Suche nach halbprivaten Test-Forks aus: was gebraucht wird,
ist keine verschollene Einzeländerung, sondern eine Treibergeneration.

## 4. Was zu tun ist

### 4.1 Den zurückgenommenen Patch löschen

`patches/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch` und
`patches/mt7915-filogic-syncpowersave-patch.sh`. Beide sind inaktiv, aber sie
laden zum Einschalten ein — und das wäre schädlich (2.1). Wer den Vorgang später
nachlesen will, findet ihn in diesem Dokument und in der Git-Historie.

### 4.2 Gluons Puffer-Deckel nachziehen — mit einer Einschränkung

Gluon-Commit `8f38662f` (David Bauer, 2025-11-26, *gluon-core: limit size of
wireless buffers*) begrenzt die WLAN-Puffer:

> By default, the kernel configures the buffers for wireless PHYs to 4MB for 11n
> radios and 16MB for 11ac and above. For our RAM constrained devices, this has
> the effect of the buffers potentially filling up to cause a OOM oops.

Der Commit liegt **nicht** in `v2023.2.x`. Unsere Fassung von
`01-gluon-core-codel-memusage` greift nur bei Geräten mit **≤ 32 MB RAM** — die
Gluon 2023.2 gar nicht mehr unterstützt. Bei uns ist also auf **keinem** Knoten
ein Limit gesetzt, es gilt die Kernelvorgabe von 16 MB je 11ac+-PHY.

Der Backport ist 13 Zeilen Shell, kein Kernel, kein Treiber. Aber die neue Fassung
staffelt nur bis 128 MB RAM:

| Gerät | MemTotal | `8f38662f` setzt |
|---|---|---|
| ZyXEL NWA50AX Pro, MERCUSYS MR90X | ~487 MiB | **kein Limit** |
| Cudy WR3000S | ~236 MiB | **kein Limit** |
| ramips-mt7621 mit 128 MB | ~123 MiB | 2 MB |

Für die filogic-Geräte — genau die mit dem Symptom — ändert der Commit also
nichts. Zwei Möglichkeiten:

* **nur backportieren:** hilft der 128-MB-Klasse, ist unstrittig, weil es
  Gluon-Upstream ist.
* **backportieren und die Staffel weiterziehen**, etwa 4 MB ab 256 MB RAM. Das
  ist dann unsere eigene Entscheidung und sollte gemessen werden: Ziel ist,
  dass der Backlog gar nicht erst in die Höhe läuft, auf die
  `neanderfunk-mt7915-backlog` reagiert. Gegen Durchsatzverlust spricht Bauers
  eigene Zahl: 512 kB reichten auf einem stärkeren Board für ~100 Mbit/s an drei
  Clients.

### 4.3 Was **nicht** abgeschaltet gehört

Beide laufenden Gegenmaßnahmen behandeln reale, upstream unerledigte Fehlerbilder:

* der `wifi_firmware`-Reboot deckt 2.2 ab — Issue #690 ist offen,
* der Backlog-Neustart deckt 2.1 ab — der Fix dafür ist in unserer
  Treiberversion nicht verfügbar.

Kontraproduktiv ist keines von beidem. Sinnvoll wäre nur, sie nach 4.2 noch
einmal gegen die Logs zu halten: greift der Backlog-Watchdog mit gedeckelten
Puffern seltener, war der Deckel die bessere Behandlung.

Eine Frage an die Paketfeed-Seite: `backlog.sh` nimmt aus
`iw phy <phy> get txq` das zweite Feld der `Backlog`-Zeile und vergleicht es mit
50. Ob das Bytes oder Pakete sind, entscheidet, ob die Schwelle sinnvoll liegt —
das wäre einmal an einem Knoten zu bestätigen.

## 5. Reihenfolge

1. Patch und Skript aus 4.1 löschen — kostet nichts, verhindert einen Fehlgriff.
2. `8f38662f` backportieren (4.2, erste Variante).
3. Auf einem filogic-Knoten messen, ob eine weitergezogene Staffel den Backlog
   drückt. Erst dann 4.2, zweite Variante.
4. Alles Weitere mit 2025.1 — dort kommt mt76 vom November 2025 mit, inklusive
   des kompletten PS-Strangs aus 2.1.

## 6. Quellen

* [openwrt/mt76 #1068](https://github.com/openwrt/mt76/issues/1068) — die Regression, die zum Revert führte
* [openwrt/mt76 #690](https://github.com/openwrt/mt76/issues/690) — MCU-Timeout, offen seit 2022
* [openwrt/mt76 #922](https://github.com/openwrt/mt76/issues/922) — MT7981/filogic, Durchsatzeinbruch
* Gluon-Commit `8f38662f44f5df69357ced93f166000716f018b3`
* mt76-Commits `be3aad4c2e10`, `ca81c5c18ec8`, `9a46d8d21d2a`, `9e613fb007f5`, `f8b59ca3be7b`
