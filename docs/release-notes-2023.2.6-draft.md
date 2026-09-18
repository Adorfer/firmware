# Release Notes 2023.2.6 — ENTWURF

**Neanderfunk-Firmware auf Basis von Gluon v2023.2.6**

> **Entwurf.** Versionsnummer, Datum und die Links auf den Firmware-Server
> fehlen noch und werden beim RC eingesetzt. Reihenfolge und Auswahl der
> Punkte sind zur Diskussion gestellt.

Diese Fassung löst die Stable vom März 2026 (`26030610sta`) ab, für die es
keine Release Notes gab. **Sie gilt genauso für Knoten auf der Dezember-Stable
(`25122513sta`):** Zwischen Dezember und März lag faktisch nur ein
OpenWrt-Versionssprung, keine funktionalen oder architektonischen Änderungen.
Wer also seit Dezember nicht aktualisiert hat, findet hier trotzdem den
vollständigen Unterschied.

Rückmeldungen bitte an:

- E-Mail: [projekt@neanderfunk.de](mailto:projekt@neanderfunk.de)
- Mastodon: [@neanderfunk@nrw.social](https://nrw.social/@neanderfunk)
- Telegram: [Neanderfunk-Gruppe](https://t.me/+_rWKhNAJyvg5MWY0)

## Router mit wenig Arbeitsspeicher laufen stabiler

Betrifft alle Geräte mit 64 MB RAM, also einen großen Teil der älteren
Dualband-Router.

- **Komprimierter Auslagerungsspeicher im RAM** (zram) ist auf diesen Geräten
  jetzt an. Selten benutzte Teile der Dienste werden komprimiert, das schafft
  Platz für den Dateicache.
- **Weniger Prozesse im Hintergrund:** Die Sandbox um einzelne Dienste entfällt
  auf diesen Geräten, ebenso ein nicht benötigter Zufallszahlendienst. Zwei
  Hintergrunddienste laufen jetzt als sparsames Shell-Skript statt als
  Lua-Programm.
- **Kein Absturz mehr bei leerem Empfangspuffer** auf ath9k-Geräten unter
  Speicherdruck.
- Auf Geräten mit viel Speicher wurden im Gegenzug die **Netzwerkpuffer
  angehoben**, was bei hohem Durchsatz hilft.

## Der Knoten hilft sich selbst

- **Die Prüfer schweigen nicht mehr die erste Stunde.** Bisher liefen sie in
  den ersten 60 Minuten nach einem Neustart gar nicht — wer direkt nach einem
  Reboot ins Protokoll sah, sah nichts, egal ob der Knoten gesund war oder
  nicht. Jetzt laufen sie ab 5 Minuten Laufzeit und **melden**, halten sich mit
  Eingriffen aber weiterhin bis zur ersten Stunde zurück. Die gezählten
  Verstöße laufen dabei weiter, ein noch bestehendes Problem wird also sofort
  behandelt statt von vorn gezählt.
- **Auch der WLAN-Neustart wartet jetzt ab.** Er passierte bisher unabhängig
  von der Laufzeit.
  <!-- TODO: Wenn geklärt ist, woher die Neustartschleifen der März-Stable
       kamen (eulenfunk-hotfix/rebootIfNoGw.sh?), gehört das hier als
       behobener Fehler hin - mit belegter Ursache, nicht als Vermutung. -->
- **Neustartgründe bleiben erhalten.** Der Knoten schreibt mit, warum er neu
  gestartet ist; die letzten **sechs** Einträge überstehen den Neustart. Das
  macht aus „war weg" ein „war weg, weil …".
- **Neue Prüfer für bekannte Hängerfälle:** ein klemmender WLAN-Chip (ath10k),
  ein hängender Ethernet-Sendepfad bei bestimmten Cudy-Geräten — dort wird
  zuerst der Port zurückgesetzt und erst dann neu gestartet —, und ein
  Fernprotokoll, das nach einem Adresswechsel ins Leere lief.
- Der Watchdog startet nicht mehr hart durch, wenn er im ungünstigen Moment
  ein Signal bekommt, und wartet vor einem Neustart auf das Schreiben der
  Daten.

## Mesh-VPN

- **Kein Dauerlauf mehr, wenn das Internet fehlt.** Ein Knoten ohne
  Internetzugang hat bisher ununterbrochen versucht, den VPN-Tunnel
  aufzubauen, und dabei die CPU belegt. Jetzt wartet er zwischen den
  Versuchen.
- **Zwei zusätzliche Supernodes sind in der Firmware hinterlegt.** Gehen sie
  in Betrieb, verteilt sich das Mesh-VPN auf mehr Server, ohne dass die Router
  ein Update brauchen.

## WLAN

- **Die Sendeleistung wird nicht mehr festgeschrieben.** Bisher konnte ein
  einmal gesetzter Wert dauerhaft hängenbleiben, auch wenn er nicht mehr
  passte. Der Router folgt jetzt wieder den Vorgaben der Firmware.
- **Kanal und Kanalbreite können auf Wunsch über Updates hinweg erhalten
  bleiben.**
- **Die Kanalauslastung auf der Karte ist wieder realistisch** — vorher
  konnten unsinnig hohe Werte auftauchen.
- Auf Geräten mit MT7530-Switch ist eine Stromsparfunktion abgeschaltet, die
  in der Praxis Verbindungsabbrüche verursacht hat.

## Bedienung auf dem Router

Wer sich per SSH anmeldet, findet eine neue Übersicht und mehrere
Hilfsbefehle:

- **`nodestatus`** zeigt auf einen Blick Modell, Domain, Firmware, Uplink,
  Gateway, VPN, Clients, WLAN-Kanäle und Ports — inklusive
  **SoC-Temperatur** und der **öffentlichen IPv4 mit Rückwärtsauflösung und
  Provider**.
- **`vpn on|off`** schaltet das Mesh-VPN dauerhaft, **`flash <url>`** holt und
  prüft eine Firmware, **`lanrole`/`wanrole`** zeigen und setzen Portrollen,
  **`routername`** den Knotennamen.
- **Warnungen statt stiller Fehler:** Der Knoten meldet, wenn der WLAN-Kanal
  nicht zur Firmware passt, wenn eine Offline-SSID dauerhaft festgeschrieben
  wurde oder wenn eine Portrolle den CPU-Port trifft.
- **Laufzeitänderungen werden nicht mehr versehentlich dauerhaft.** Ein `uci
  commit` in der Shell schreibt nur noch das ins Flash, was auch gemeint war.

## Konfigurationsseite im Browser

- **Neues Erscheinungsbild, alles auf einer Seite**, auf dem Handy deutlich
  besser bedienbar.
- **Setup-WLAN:** Ein kurzer Tastendruck öffnet ein offenes WLAN
  `setup.gluon_<MAC>`, über das sich der Router einrichten lässt — praktisch,
  wenn kein Kabel zur Hand ist. Es schaltet sich nach 20 Minuten von selbst
  wieder ab.
- Ruft man die Seite auf, **ohne etwas zu speichern, bleibt das Flash
  unberührt**.
- Nach einem Update zeigt der Browser nicht mehr die alte Seite aus seinem
  Zwischenspeicher.

> **Bekannte Einschränkung:** Der kleine Browser, den Android für
> Anmeldeseiten öffnet, kann keine Dateien hochladen. Ein Firmware-Upgrade
> über die Setup-Seite gelingt dort nicht — dafür die Seite
> `http://setup.gluon` im normalen Browser öffnen. Kein Fehler des Routers.

## Statusseite

- Die Werte werden **live aktualisiert** und kommen direkt vom Knoten.
- Neu: **Ethernet-Geschwindigkeit je Port**, **Temperaturen**, und eine Zeile
  zur Offline-SSID mit Zählern.

## App und Karte

- **Die NodeMonitor-App zeigt die Zahl der Knoten im Netz wieder richtig.**
  Vorher wurden dreistellige Werte angezeigt, weil jeder Weg statt jedes
  Knotens gezählt wurde.

## Für Betreiber mehrerer Knoten

- **Zeitschaltung fürs WLAN** (ap-timer) ist jetzt fester Bestandteil, mit
  eigener Seite im Config-Mode.
- **Serverseitiger Domainwechsel:** Ein Knoten kann auf Zuruf in eine andere
  Domain umziehen, ohne dass jemand vor Ort sein muss. Die Anweisung ist
  signiert und wird nur angenommen, wenn sie dieselbe Vertrauensstufe erfüllt
  wie ein Firmware-Update.

## Neue und wieder unterstützte Geräte

*(Liste beim RC einsetzen — u. a. D-Link AQUILA PRO AI M30, ZyXEL NWA55AXE,
Mercusys MR90X, Cudy-Modelle mit 2,5-Gigabit-Port.)*

## Kleinere Korrekturen

Dazu eine größere Zahl von Reparaturen, die einzeln aufzuführen wenig brächte.
Der Schwerpunkt lag bei den **Verbindungsprüfern** (linkcheck): Mehrere
Prüfungen waren wirkungslos, weil sie nie zutrafen, und einzelne griffen genau
verkehrt herum. Sie tun jetzt das, was ihr Name sagt. Hinzu kommen zahlreiche
Sparsamkeitskorrekturen — Konfiguration wird einmal je Lauf gelesen statt
mehrfach, und der WLAN-Neustart löst keine überflüssige Neukonfiguration mehr
aus.

## Hinweise zum Umstieg

- Die Konfiguration bleibt erhalten, der Router kommt von selbst zurück.
- Geräte mit 4 MB Flash und 32 MB RAM werden nicht mehr unterstützt; für sie
  gibt es einen eigenen Endstand.
