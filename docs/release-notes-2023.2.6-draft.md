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

## Einrichten per WLAN, ohne Kabel

- **Ein kurzer Druck auf die Taste öffnet ein offenes WLAN**
  `setup.gluon_<MAC>`. Darüber lässt sich der Router einrichten — auch dann,
  wenn kein Netzwerkkabel zur Hand ist oder das Gerät an einer schlecht
  erreichbaren Stelle hängt.
- Handy oder Notebook verbinden, die Einrichtungsseite öffnet sich von selbst;
  sonst `http://setup.gluon` aufrufen.
- Das Setup-WLAN **schaltet sich nach 20 Minuten von selbst wieder ab**, es
  bleibt also nicht versehentlich offen.

> **Bekannte Einschränkung:** Der kleine Browser, den Android für
> Anmeldeseiten öffnet, kann keine Dateien hochladen. Ein Firmware-Upgrade
> gelingt dort nicht — dafür `http://setup.gluon` im normalen Browser öffnen.
> Kein Fehler des Routers.

## Neue Konfigurationsseite

- **Neues Erscheinungsbild, alles auf einer Seite**, auf dem Handy deutlich
  besser bedienbar.
- Ruft man die Seite auf, **ohne etwas zu speichern, bleibt das Flash
  unberührt**.
- Nach einem Update zeigt der Browser nicht mehr die alte Seite aus seinem
  Zwischenspeicher.
- Fehlermeldungen benennen jetzt das konkrete Problem, statt nur zu scheitern.

## Statusseite

- Die Werte werden **live aktualisiert** und kommen direkt vom Knoten.
- Neu: **Ethernet-Geschwindigkeit je Port**, **Temperaturen**, und eine Zeile
  zur Offline-SSID mit Zählern.

## Die App NodeMonitor — vermutlich die am meisten übersehene Neuerung

Mit **NodeMonitor** sieht man **jeden Freifunk-Knoten in Funkreichweite, ohne
sich zu verbinden**:

- [Im Play Store](https://play.google.com/store/apps/details?id=net.freifunk.darmstadt.nodewhisperer&hl=de)
- [Quelltext auf GitHub](https://github.com/freifunk-darmstadt/NodeMonitor)

Die App gibt es **nur für Android**. Das liegt nicht am Aufwand: iOS gibt
Anwendungen keinen Zugriff auf die WLAN-Suche, und genau die braucht es
hier.
Der Router sendet die Angaben in den Beacons seines Client-WLANs mit; die App
liest sie im Vorbeigehen aus. Nützlich beim Aufstellen, beim Suchen eines
Standorts und bei der Frage „ist der Knoten dort oben eigentlich noch im
Netz?".

- **Die Zahl der Knoten im Netz stimmt wieder.** Vorher standen dort
  dreistellige Werte, weil jeder *Weg* statt jedes *Knotens* gezählt wurde.
- **Die Anzeige „Gateway" zeigt jetzt wirklich den Gateway**, vorher war es
  der Wert eines VPN-Nachbarn.
- Kein Dauerprotokoll mehr im Systemlog auf Knoten ohne Multidomain.

Wer sie beim letzten Release übersehen hat: Es lohnt sich, einmal
hineinzuschauen.

## SSH-Konsolenzugriff

Auf der Konsole gibt es eine neue Übersicht und mehrere Hilfsbefehle:

- **`nodestatus`** zeigt auf einen Blick Modell, Domain, Firmware, Uplink,
  Gateway, VPN, Clients, WLAN-Kanäle und Ports — inklusive
  **SoC-Temperatur** und der **öffentlichen IPv4 mit Rückwärtsauflösung und
  Provider**.
- **`vpn on|off`** schaltet das Mesh-VPN dauerhaft, **`flash <url>`** holt und
  prüft eine Firmware, **`lanrole`/`wanrole`** zeigen und setzen Portrollen,
  **`routername`** den Knotennamen.
- **Warnungen statt stiller Fehler:** Der Knoten meldet, wenn der WLAN-Kanal
  nicht zur Firmware passt oder wenn eine Offline-SSID dauerhaft
  festgeschrieben wurde.
- **Mögliche unerwünschte Wechselwirkungen zwischen Paketen ausgeräumt.** Der
  Fall: Ein Paket setzt etwas absichtlich nur vorübergehend — die
  Offline-SSID, während kein Gateway da ist, oder das abgeschaltete WLAN
  während der Zeitschaltung. Ein anderes Paket speichert kurz darauf aus
  eigenem Anlass die Konfiguration ins Flash **und nimmt den fremden
  Zwischenzustand mit**. Ab da ist er dauerhaft: Der Router hieß dann auch
  nach der Störung weiter `FF_Offline_…` oder ließ das WLAN aus. Betroffen
  waren ssid-changer, WLAN-Zeitschaltung (ap-timer), WLAN-Taste und
  Domainwechsler. Dieselbe Falle gab es auf der Konsole und beim bloßen
  Ansehen einer Konfigurationsseite; beides schreibt jetzt nichts Fremdes
  mehr mit.

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
  Eingriffen aber weiterhin bis zur ersten Stunde zurück. Die bisher
  aufgelaufenen Fehlermeldungen werden dann, wenn der Fehler nach wie vor
  besteht, sofort behandelt.
- **Auch der WLAN-Neustart wartet jetzt ab.** Er passierte bisher unabhängig
  von der Laufzeit.
- **Neustartschleifen sind seltener und nachvollziehbar.** Ein Knoten, der
  wiederholt seinen Gateway verliert, startet weiterhin neu — nun aber
  frühestens nach 60 Minuten Laufzeit statt nach gut 30, und was in der ersten
  Stunde passiert, steht im Protokoll. Ein Neustart behebt einen fehlenden
  Gateway nicht; ob er bei Netzausfall überhaupt erfolgen soll, sehen wir uns
  für die nächste Generation an.
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

## Vorbereitung auf eine Multidomain-Firmware

Beim letzten Anlauf mit einer Multidomain-Firmware, vor einigen Jahren, landete
ein großer Teil der Knoten bei der Ersteinrichtung in der **ersten Domain der
Auswahlliste** — und blieb dort. Das ließ sich danach nur von Hand und vor Ort
wieder geraderücken.

Dafür gibt es jetzt eine Lösung: Ein Knoten kann **auf Zuruf in die richtige
Neanderfunk-Domain umziehen**, ohne dass jemand hinfahren muss. Die Anweisung
dazu ist genauso abgesichert wie ein Firmware-Update — sie muss von mehreren
Personen unterschrieben sein, und der Knoten nimmt sie nur an, wenn sie
dieselbe Vertrauensstufe erfüllt, die er auch für neue Firmware verlangt.

## Geräte

**Neu unterstützt: D-Link AQUILA PRO AI M30.** Die Installation läuft über das
OpenWrt-Initramfs, weil es für dieses Gerät kein Recovery-Image gibt; die
Anleitung dazu kommt getrennt.

**Einige Zielplattformen sind entfallen.** Wir bauen nicht mehr für Hardware,
von der es realistischerweise nie einen Knoten bei uns geben wird — darunter
Allwinner (sunxi), Realtek RTL838x, sehr alte x86-Varianten und generische
ARM-Systeme. Für die meisten davon kennt der Gluon-Zensus in **ganz
Deutschland keinen einzigen Knoten**. Das spart Bauzeit, die den Geräten
zugutekommt, die tatsächlich im Feld stehen. Sollte doch jemand so ein Gerät
betreiben wollen: melden, dann bauen wir es wieder mit.

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


## P.S., ganz nebenbei

Wer gerade dabei ist, die letzten Geräte mit 4 MB Flash zu ersetzen: Nehmt die
Geräte mit **64 MB Arbeitsspeicher** gleich mit. Diese Version hält sie noch am
Laufen — dafür sind zram, die entschlackten Hintergrunddienste und die
sparsameren Skripte oben da —, aber in künftigen Gluon-Versionen werden auch
sie wegfallen. Das ist keine Drohung, nur Arithmetik.

Und falls das am Gerät scheitert: Wir haben noch ein paar **Genexis EX400** im
Austauschprogramm liegen. Einfach fragen.
