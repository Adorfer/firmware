# Testing-Release-Notes `26091213bro`

**Neanderfunk-Testfirmware (broken) auf Basis von Gluon v2023.2.6**

Firmware-Stand: `26091213bro`, gebaut am 12.09.2026.

Das ist eine **Testversion**. Sie steckt voller Neuerungen aus den letzten
zwei Wochen, ist aber noch nicht final. Wer mag, spielt sie auf einen
Router, schaut sich um und meldet an die Neanderfunk-Admins, was auffällt:
was gut ist und was nicht.

## Einrichtung (Setup-Mode)

- **Neues Design:** Alles auf einer Seite, und beim Wechseln geht keine
  Eingabe mehr verloren. Auch auf dem Handy im Hochformat bedienbar, mit
  Dark Mode. Fehler werden direkt am Feld erklärt. Und das Setup trägt jetzt
  das Neanderfunk-Logo 🙂
- **Leichter erreichbar:** Neben http://192.168.1.1 geht jetzt auch
  http://setup.gluon oder http://gluon.setup.
- **Einrichten per WLAN, ohne Kabel:** Im Setup-Mode spannt der Router ein
  eigenes WLAN auf.
  - Name: `setup.gluon_` plus die letzten 4 Stellen der MAC-Adresse
  - Passwort: `freifunk_` plus die ersten 2 Stellen, alles klein
  - Beispiel: Aus der MAC `28:d1:27:db:33:f1` werden das WLAN
    `setup.gluon_33f1` und das Passwort `freifunk_28`.

  Nach dem Verbinden öffnet sich die Setup-Seite von allein. Nach
  20 Minuten schaltet sich das Setup-WLAN ab, per Kabel geht es weiter.
- **Neue Einstellungen:**
  - **Nodeplacer** erlauben oder verbieten: Die Community kann den Router
    dann ohne Besuch vor Ort in eine andere Domäne umziehen.
  - **WLAN-Taste** belegen, z. B. als Nachtmodus mit LEDs aus.
  - **Client-WLAN nach Zeitplan** (AP-Timer).
- **Ungeduld wird nicht mehr bestraft:** Wer zweimal auf „Speichern &
  Neustarten“ tippt, bekommt keinen Router mehr, der plötzlich „OpenWrt“
  heißt und auf UTC-Zeit steht.

## WLAN

- Kanäle und Sendeleistung bleiben so, wie eingestellt, auch nach Updates.
- Router bleiben nicht mehr auf der Offline-SSID hängen.

## Stabilität

- Weniger unnötige automatische Neustarts.
- Die NodeMonitor-App zeigt den Gateway-Status richtig an.

## Statusseite des Routers

- Die aktiven SSIDs
- Offline-SSID-Zähler: gerade offline, Offline-SSID seit dem Start,
  Gateway-Verluste
- Link-Geschwindigkeit je LAN-Port
- Flash- und RAM-Größe, Boardname und CPU

## SSH-Login

- Neu gestaltet und farbig, mit mehr Infos und Warnungen.
- `nodeinfo` zeigt Nachbarn und LAN-Ports.
- LAN-Ports lassen sich per Befehl zwischen Mesh und Client umschalten.
- `help` ist vollständig.

## Beim Testen besonders interessant

- Einrichten per WLAN mit iPhone, Laptop oder älteren Android-Handys: Öffnet
  sich die Setup-Seite von allein?
- Bleiben Kanäle und Sendeleistung nach dem Update erhalten?
