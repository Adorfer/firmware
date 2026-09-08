# Fallstudie: ein Kernelfehler, der nur beim Kaltstart zuschlägt

Wie wir im September 2026 einen Fehler gefunden haben, der im März 2026 57
Knoten ausfallen ließ, und was davon auf andere Untersuchungen übertragbar ist.

Geschrieben für Leute, die vor einem ähnlichen Problem stehen. Der konkrete
Fehler ist am Ende nur ein Beispiel; interessanter ist der Weg dorthin und die
Stellen, an denen wir uns geirrt haben.

---

## 1. Das Symptom

Zwei Router — ein TP-Link Archer C25 v1 und ein TL-WR1043ND v2 — kamen nach
einem Stromausfall nicht wieder hoch. Kein LED-Blinken, kein Pushbutton-TFTP,
kein U-Boot-Rescue. Der Ethernet-Link kam hoch, aber kein Ping.

Beide hatten in den Tagen davor mehrere sysupgrades klaglos überstanden. Es war
der erste Kaltstart danach.

Die Arbeitshypothese des Betreibers: Kalt- und Warmstart unterscheiden sich,
vermutlich sei der Bootloader beschädigt.

## 2. Was wir zuerst untersucht haben — und warum es falsch war

Wir haben mehrere Stunden in Richtungen investiert, die sich als Sackgassen
erwiesen. Das ist der Teil, den Berichte üblicherweise weglassen, und genau der
Teil, der beim nächsten Mal Zeit spart.

**Flash-Überlauf.** Naheliegend: passt das Image überhaupt in die Partition?
Nachgerechnet — Archer C25 6 423 367 Bytes in eine 7 995 392 Bytes große
`firmware`-Partition, WR1043ND v2 6 816 586 in 8 192 000. Beides passt mit
über einem Megabyte Luft. U-Boot liegt bei beiden ohnehin in einer
schreibgeschützten Partition außerhalb.

**Eigene Patches am Flash-Treiber.** Wir pflegen einen Patch, der eine
JEDEC-ID für einen Zbit-SPI-NOR ergänzt. Verdächtig — aber er liegt unter
`target/linux/ramips/`, betrifft ath79 also gar nicht.

**Swap auf Flash.** Ein Patch namens `kernelswapon-openwrt.patch` klang
alarmierend. Beim Lesen: er ändert nur das zram-Init-Skript, und angewendet
wird er ohnehin nicht.

**Die Lehre daraus:** wir haben nach einer *Ursache im Flash* gesucht, weil das
Symptom "kommt nicht mehr hoch" danach aussah. Tatsächlich hatten wir zu diesem
Zeitpunkt keinerlei Beleg dafür, wo das Gerät stehenbleibt. Wir hätten früher
sagen sollen: **ohne serielle Konsole raten wir nur.**

## 3. Die Wende: der erste Serial-Log

Der Betreiber hängte eine serielle Konsole an. Der erste Log zeigte:

```
U-Boot 1.1.4 (Jun 13 2014 - 15:14:01)
ap135 - Scorpion 1.0DRAM:
ath_ddr_initial_config(211): (16bit) ddr1 init
Tap (low, high) = (0xaa55aa55, 0x0)
 4 MB
```

**U-Boot läuft.** Damit waren alle Flash-Theorien erledigt. Der WR1043ND fand
statt 64 nur 4 MB RAM und blieb stehen.

Wir hielten das für die Erklärung — und lagen wieder daneben. Der Log des
Archer C25 zeigte **dieselben Zeilen**, bootete aber weiter. Auflösung: der C25
hat einen **zweistufigen Bootloader**. Die erste Stufe (`ap135`) meldet
tatsächlich 4 MB und lädt dann die zweite (`ap151`), die 64 MB findet. Am
Flash-Layout erkennbar: der C25 hat `factory-boot` **und** `u-boot` als
getrennte Partitionen, der 1043 nur `u-boot`. Bei einstufigen Geräten bedeutet
dieselbe Ausgabe einen echten DRAM-Fehler, bei zweistufigen ist sie normal.

**Die Lehre:** eine Logzeile ohne Vergleichslog ist wenig wert. Erst der
Vergleich mit einem gesunden Gerät desselben Typs — hier aus einem
Forumsarchiv — machte sie interpretierbar.

## 4. Der eigentliche Befund

Der C25-Log lief weiter bis:

```
[    0.000000] Dentry cache hash table entries: 8192 ...
[    0.000000] Inode-cache hash table entries: 4096 ...
<nichts mehr>
```

Diese Stelle ist eindeutig lokalisierbar, wenn man den Kernelquelltext danebenlegt:

```
init/main.c:1008   vfs_caches_init_early()   letzte Ausgabe
init/main.c:1009   sort_main_extable()
init/main.c:1010   trap_init() -> traps.c:2309 tlb_init()
init/main.c:1011   mm_init()                 würde "Memory: ..." drucken
```

Zwischen der letzten Ausgabe und der nächsten liegt genau eine nennenswerte
Funktion: `tlb_init()`. Auf MIPS führt sie über `r4k_tlb_configure()` zu
`r4k_tlb_uniquify()`.

Der Betreiber hatte parallel den Gluon-Merge `3ae9607e` im Verdacht, weil ein
gleichartiger Ausfall im März 2026 nach genau diesem Update aufgetreten war.
Der Merge zieht den OpenWrt-Pin und damit **Kernel 5.15.189 → 5.15.198**.

In den Stable-Changelogs dieser neun Releases:

```
5.15.190  MIPS: mm: tlb-r4k: Uniquify TLB entries on init          <- Auslöser
5.15.197  MIPS: mm: Prevent a TLB shutdown on initial uniquification  <- Fix, reicht nicht
```

Aus dem Commit-Text des Fixes:

> „a TLB shutdown may occur if multiple matching entries are detected upon the
> execution of a TLBP or the TLBWI/TLBWR instructions. **Given that we don't
> know what entries we have been handed** …"

Damit war die Warm/Kalt-Asymmetrie erklärt: die Funktion arbeitet auf dem, was
der Bootloader im TLB hinterlassen hat. Beim Einschalten ist das zufällig, nach
einem Warmstart der bereits bereinigte Inhalt des vorherigen Laufs.

## 5. Der Beweis, ohne ein Gerät zu riskieren

Der entscheidende Kniff: **Kernel per TFTP ins RAM laden und mit `bootm`
starten.** Der Flash bleibt dabei unberührt, ein Aus und Ein stellt den alten
Zustand wieder her. So lässt sich ein Kernelverdacht prüfen, ohne ein Gerät
unbrauchbar zu machen.

```
setenv serverip <server>
tftpboot 0x82000000 image.bin
bootm 0x82000000
```

Der erste Versuch scheiterte an der Ladeadresse: bei `0x81000000` überschrieb
sich der Kernel beim Entpacken selbst (`LZMA ERROR 1`). Der Kernel entpackt ab
seiner Load Address nach oben; liegt das komprimierte Image darin, ist es weg.
Bei 64 MB RAM ist `0x82000000` brauchbar.

Mit dem gepatchten Kernel aus dem RAM bootete das Gerät vollständig durch — mit
dem unveränderten Rootfs der alten Firmware aus dem Flash. Gleiche
Kernelversion, gleiche Konfiguration, nur `tlb-r4k.c` unterschiedlich.

## 6. Von „zweimal gesehen" zu einer Zahl

Zwei erfolgreiche Versuche sind kein Beleg. Die Frage, ob der Fehler
deterministisch oder sporadisch ist, entscheidet aber über die Bewertung: der
ursprüngliche Upstream-Fehler, gegen den die Uniquifizierung überhaupt gebaut
wurde, trat mit **7 von 1000** Starts auf.

Mit einer fernschaltbaren Steckdose ließen sich Kaltstarts automatisieren:
ausschalten, warten, einschalten, Bootloader abfangen, Image laden, starten,
Ergebnis einordnen. Drei Varianten **im Wechsel** statt blockweise, damit
Temperatur oder Drift alle gleich treffen.

| Variante | durchgebootet | hängt | n |
| --- | ---: | ---: | ---: |
| 5.15.198 ohne Patch | 0 | 21 | 21 |
| 5.15.198 mit Patch | 21 | 0 | 21 |
| 6.6.144 (OpenWrt 24.10.8) | 21 | 0 | 21 |

Die beiden 5.15.198-Varianten stammen aus demselben Build-Baum und
unterscheiden sich in einer gelöschten Zeile.

**Der Fehler ist deterministisch.** Dass die 57 Knoten im März über Tage
verteilt ausfielen, lag allein daran, wann sie Strom verloren — nicht daran,
dass der Fehler mal zuschlug und mal nicht.

Drei Dinge, die diese Messreihe brauchbar gemacht haben:

* **Fehlversuche getrennt zählen.** Wenn der Bootloader nicht abgefangen wurde
  oder TFTP scheiterte, ist das kein Ergebnis. In die Quote gehören nur
  Durchgänge, die tatsächlich einen Kernel gestartet haben. Im ersten Lauf
  fielen so 14 % aus, weil ein Schaltbefehl per HTTP lautlos verlorenging —
  seither wird nach jedem Schalten der Zustand zurückgelesen.
* **Eine echte Kontrolle bauen.** Nicht die alte Feldfirmware gegen die neue
  vergleichen, sondern zwei Images aus demselben Baum, die sich nur im Patch
  unterscheiden. Sonst bleibt offen, ob nicht etwas anderes den Unterschied
  macht.
* **Nichts in den Flash schreiben.** Alle 63 Durchgänge liefen über RAM. Das
  Gerät war jederzeit einen Stromzyklus von seinem Ausgangszustand entfernt.

## 7. Wie weit der Fehler reicht

Betroffen ist `arch/mips/mm/tlb-r4k.c` — nicht ath79-spezifisch, sondern für
jeden r4k-artigen MIPS-Kern übersetzt. Der Blick auf die 57 Ausfälle vom März,
aufgelöst über die OpenWrt-Gerätedefinitionen und die SoC-Gerätebäume:

| Anzahl | Target | SoC | Kern |
| ---: | --- | --- | --- |
| 50 | ath79 | qca9563 / qca9558 / ar9344 | 74Kc |
| 4 | ath79 | ar7241 | 24Kc |
| 2 | lantiq | vr9 | 34Kc |
| 1 | ramips | mt7628an | 24KEc |

Alle 57 waren MIPS, kein einziger aarch64- oder x86-Knoten. Das ist die
stärkere Aussage als die Kernverteilung, denn die Flotte enthält solche Geräte,
und sie liefen durch.

Deshalb liegt unser Patch unter `target/linux/generic/` und nicht unter
`target/linux/ath79/` — ein ath79-Patch hätte die beiden FRITZ!Box 7362 SL
(lantiq) und den Archer C50 v3 (ramips) ungeschützt gelassen.

**Nicht betroffen ist mt7621 (1004Kc):**

| Gerät | Bootloader | Kaltstarts | durchgebootet |
| --- | --- | ---: | ---: |
| Ubiquiti EdgeRouter X | Ubiquiti | 11 | 11 |
| Xiaomi Mi Router 4A Gigabit | Xiaomi | 11 | 11 |

Zwei verschiedene Bootloader auf demselben SoC zeigen dasselbe Verhalten —
damit liegt es am Kern und nicht daran, was der Bootloader zufällig im TLB
hinterlässt. Das deckt sich mit der Feldbeobachtung, dass im März kein einziger
EdgeRouter X ausfiel.

Die Gegenprobe mit dem zweiten Gerät war den Aufwand wert: bei nur einem
Gerät wäre offengeblieben, ob der Kern oder der Bootloader die Ursache ist —
und „mt7621 ist sicher" wäre eine gefährliche Verallgemeinerung gewesen.

## 8. Prüfen, was auf einem Knoten wirklich läuft

Ist ein Aufruf wegpatcht und die Funktion dadurch unbenutzt, wirft der
Übersetzer sie weg und das Symbol verschwindet:

```sh
grep -q r4k_tlb_uniquify /proc/kallsyms && echo ungeschuetzt || echo "Fix drin"
```

Das misst den **laufenden** Kernel, nicht das, was der Build vorhatte. Aber es
misst die *Abwesenheit* eines Symbols und taugt nur dort, wo man genau weiß,
warum es fehlen sollte — auf einer Firmware, die den Aufruf noch enthält (etwa
Gluon 2025.1), meldet dieselbe Prüfung fälschlich „ungeschützt".

## 9. Was davon übertragbar ist

**Erst lokalisieren, dann erklären.** Wir haben Stunden mit Hypothesen
verbracht, bevor der erste Serial-Log vorlag. Die Konsole hätte am Anfang
stehen sollen.

**Die letzte Logzeile ist eine Adresse.** Mit dem Quelltext daneben lässt sich
die Stelle oft auf wenige Funktionen eingrenzen — hier auf genau eine.

**Änderungen zwischen zwei bekannten Ständen auflisten.** Der Sprung 5.15.189 →
5.15.198 war über die Stable-Changelogs in Minuten durchsuchbar. Der Betreiber
hatte den richtigen Commit im Verdacht, konnte ihn aber nicht belegen; die
Changelogs schlossen die Lücke.

**Aus dem RAM booten, nicht flashen.** Solange man nicht weiß, ob eine Änderung
hilft, gehört sie nicht in den Flash.

**Messen statt behaupten.** Der Unterschied zwischen „hat zweimal funktioniert"
und „21 von 21" ist der Unterschied zwischen einer Vermutung und einem Befund.
Fernschaltbarer Strom macht das aus einer Tagesaufgabe eine halbe Stunde.

**Die eigenen Irrtümer aufschreiben.** Vier der fünf Fehlschlüsse in dieser
Untersuchung hätten sich vermeiden lassen, wenn jemand sie vorher notiert
hätte.

## 10. Ergebnis

`patches/999-mips-tlb-r4k-no-uniquify.patch` nimmt den Aufruf zurück und
stellt das Verhalten bis 5.15.189 wieder her. Begründung und Messwerte stehen
im Kopf der Patchdatei. Beim Umstieg auf Gluon 2025.1.1 oder neuer kann er weg,
siehe Kapitel 4.4 in `migration-2025.1-targets.md`.
