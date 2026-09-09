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

**Das Netzteil.** Die einzige der frühen Hypothesen, die der Betreiber sofort
und sauber ausgeräumt hat: drei verschiedene Netzteile am Archer C25, darunter
ein fabrikneues 12 V / 3 A, immer dasselbe Bild. Das kostete zehn Minuten und
nahm eine ganze Klasse von Erklärungen vom Tisch. Die Reihenfolge stimmte hier:
erst das billig Prüfbare ausschließen.

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

**Auf diesem Gerät ist der Fehler deterministisch** — er trat in jedem
einzelnen Durchgang auf, nicht in jedem zehnten. Dass die 57 Knoten im März
über Tage verteilt ausfielen, lag also daran, wann sie Strom verloren, und
nicht daran, dass der Fehler mal zuschlug und mal nicht.

Die Einschränkung „auf diesem Gerät" ist wichtig und war uns an dieser Stelle
noch nicht klar; siehe Kapitel 7.

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

**Welche Boards betroffen sind, lässt sich am CPU-Kern nicht ablesen.** Das war
die Überraschung am Ende, und sie hat eine bereits fertig formulierte Aussage
gekippt:

| Gerät | SoC | Kern | RAM | ungepatcht | gepatcht |
| --- | --- | --- | ---: | --- | --- |
| TP-Link Archer C25 v1 | QCA956X | 74Kc | 64 MB | **0 von 21** | 21 von 21 |
| TP-Link TL-WR1043ND v2 | QCA9558 | 74Kc | 64 MB | **0 von 20** | 20 von 20 |
| TP-Link TL-WDR3600 v1 | AR9344 | 74Kc | 128 MB | 11 von 11 | — |
| Ubiquiti EdgeRouter X | MT7621 | 1004Kc | 256 MB | 11 von 11 | — |
| Xiaomi Mi Router 4A Gigabit | MT7621 | 1004Kc | 128 MB | 11 von 11 | — |

Beide betroffenen Geräte sind damit in beide Richtungen gemessen: sie booten
ungepatcht nie und gepatcht immer. Beim WR1043ND lagen zwischen den beiden
Armen 40 Minuten, gemessen wurde am selben Gerät über dieselbe geschaltete
Steckdose und **dasselbe Netzteil**, und der Kernel war in beiden Fällen
5.15.198 — der Unterschied war ausschließlich der Patch.

Das Netzteil ausdrücklich zu nennen lohnt, weil es die naheliegendste
Rückfrage vorwegnimmt. Es ist seit dem Xiaomi eines mit PEN-Bezug; vorher
hatten wir sporadische Aussetzer des seriellen Links, die Messreihen
verdorben haben. Seither trat kein einziger leerer Mitschnitt mehr auf. Wer
solche Reihen selbst fährt: eine eigene Ergebniskategorie für "nichts
empfangen" ist Pflicht, sonst zählt man Störungen der Messstrecke als
Gerätefehler — genau das ist uns beim Xiaomi einmal passiert.

Der WDR3600 ist ein 74Kc wie die beiden betroffenen Geräte und bootet trotzdem
durch. Wir hatten vorher schon „auf MIPS 74Kc hängt es" in den Patchkopf
geschrieben — das war falsch, und nur weil der Betreiber auf einer dritten
Messung bestand, ist es nicht so veröffentlicht worden.

Richtig ist: **deterministisch je Gerät, aber nicht je Kern.** Das passt zum
Mechanismus, denn `r4k_tlb_uniquify()` arbeitet auf dem, was der Bootloader im
TLB hinterlassen hat, und das unterscheidet sich von Board zu Board.

Auffällig, aber mit fünf Geräten nicht belegt: beide betroffenen haben 64 MB
RAM, alle nicht betroffenen mehr. Das ist eine Beobachtung, keine Erklärung.

### Zwei Alternativen, die wir geprüft und ausgeschlossen haben

**Stack-Überlauf.** Upstream gibt es im 6.6-Zweig einen Commit
`231ac951faba` („kmalloc tlb_vpn array to avoid stack overflow"), der 5.15 nie
erreicht hat. Unsere Fassung legt das Feld mit fester Größe auf dem Stack an:

```c
unsigned long tlb_vpns[1 << MIPS_CONF1_TLBS_SIZE];   // 64 Einträge
int tlbsize = current_cpu_data.tlbsize;              // kann über Config4 wachsen
```

Wäre `tlbsize` größer als 64, liefe die Schleife über das Feld hinaus — und ein
zerschossener Stack erklärt Geräteabhängigkeit sehr gut. Gemessen an allen drei
Geräten über `/proc/cpuinfo`: `tlb_entries: 32`. Das Feld ist doppelt so groß
wie nötig. Ausgeschlossen.

**Konsolenübergabe.** Es gibt einen bekannten ar71xx-Fehler von 2016
(„fix nondeterministic hangs during boot"), bei dem die Early Console
abgeschaltet wurde, bevor der UART fertig gesendet hatte — ein Timing-Fehler,
der je nach Alignment des Compilats auftrat oder nicht. Das Muster passt
verblüffend gut. Es passt nur nicht zur Stelle: die Übergabe liegt im
erfolgreichen Bootlog bei `0.297` bis `0.320` Sekunden, unser Hänger dagegen
noch bei `0.000000`, während die Early Console die einzige ist. Ausgeschlossen.

Beide Hypothesen kamen vom Betreiber und waren gut begründet. Sie zu prüfen hat
je zehn Minuten gekostet und beide Male eine Zahl geliefert statt einer
Meinung — das ist der Unterschied zwischen Ausschließen und Abtun.

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

**Am Image lässt sich das nicht prüfen, und der Umweg lohnt nicht.** Wir haben
es versucht: Kernel aus dem Sysupgrade-Image herausgelöst (LZMA-Kopf bei
`0x200`, Properties-Byte `0x6d` — nicht `0x5d`, worauf die übliche Suche
anspringt), sauber entpackt, und dann `strings` darauf losgelassen. Ergebnis:
`r4k_tlb_uniquify` findet sich auch im nachweislich **ungepatchten** Kernel
nicht. Der Grund ist kallsyms selbst: die Namenstabelle liegt tokenkomprimiert
im Abbild, nicht als Klartext. Erst `/proc/kallsyms` dekodiert sie zur
Laufzeit.

Auch die naheliegenden Ersatzmerkmale tragen nicht. Die OpenWrt-Revision im
TP-Link-Header (`r24256+14-…`) ist bei gepatchtem und ungepatchtem Build
identisch — sie zählt die Commits des OpenWrt-Baums, und der Patch landet über
`copy_into_tree` in `target/linux/generic/hack-5.15/`, ohne sie zu verändern.
Und die entpackten Kernel sind exakt gleich groß, obwohl ihr Inhalt sich ab
Byte 1027 unterscheidet.

Praktische Folge: **plane die Verifikation auf einem laufenden Gerät ein, nicht
auf der Datei.** Wer den Build nicht selbst angestoßen hat, kann einem fremden
Image nicht ansehen, ob der Patch drin ist. Eine veröffentlichte Patchliste
neben den Images (`site/build-info.txt`) schließt diese Lücke — unser
Build-Host legt sie unter `running/` nicht mit ab, und genau dort hätte sie die
Frage in zehn Sekunden beantwortet.

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

**Den Rohmitschnitt lesen, nicht den Zustandszähler.** Beim Flashen des
WR1043ND blieb das Skript viermal in Folge stecken, weil es auf den Prompt
`ath>` wartete. Das Board meldet sich mit `ap135>` — und im Rohmitschnitt stand
die ganze Zeit `<INTERRUPT>`, der Beweis, dass Ctrl-C längst ankam. Aus den
Fehlschlägen wurde stattdessen auf eine gebrochene TX-Ader geschlossen, was den
Betreiber zweimal an den Aufbau schickte. Ein Blick in die Rohdaten statt auf
das Ergebnisfeld hätte das beim ersten Versuch erledigt.

**Ein Loopback-Test prüft nicht, was man glaubt.** Die Brücke zwischen den
beiden Steckerbuchsen bestätigt Adapter, Kabel und Crimp — aber gerade nicht
den Übergang Buchse → Pin auf der Platine, denn dafür sind die Buchsen ja
abgezogen. Genau diese Stelle war verdächtig.

## 10. Warum wir 6.6 nicht zurueckportiert haben

Naheliegender Einwand: 6.6 hat das Problem nicht, also dessen Loesung
uebernehmen. Wir haben den Rueckport als Proof of Concept gebaut und gemessen.

Vier Arme, je per TFTP ins RAM geladen, der Flash bleibt unangetastet.

| Arm | | durch | haengt |
|---|---|---:|---:|
| A | 5.15.198 ohne Patch | 0 | 21 |
| B | 5.15.198 mit unserem Patch | 21 | 0 |
| C | 6.6.144 (OpenWrt 24.10.8) | 21 | 0 |
| D | 5.15.198, 6.6-Loesung rueckportiert | 20 | 0 |

Arm D funktioniert. Der Unterschied liegt im Umfang:

| | Arm B | Arm D |
|---|---:|---:|
| geaenderte Codezeilen | 3 | 277 |
| Hunks | 2 | 7 |
| Dateien | 1 | 5 |

```
arch/mips/include/asm/cpu-info.h
arch/mips/include/asm/mipsregs.h
arch/mips/kernel/cpu-probe.c
arch/mips/kernel/cpu-r3k-probe.c
arch/mips/mm/tlb-r4k.c
```

Arm B aendert nur `tlb-r4k.c`. Arm D fasst zusaetzlich die CPU-Erkennung an und
faellt damit in den Bootpfad jedes MIPS-Geraets, nicht nur der betroffenen.
Gemessen haben wir 20 Kaltstarts auf einem Geraetemodell — genug fuer den
Nachweis der Funktion, nicht fuer den Ausschluss von Regressionen auf der
uebrigen Flotte.

### Arm B im Volltext

```diff
From: Freifunk im Neanderland <projekt@neanderfunk.de>
Subject: MIPS: tlb-r4k: drop the call to r4k_tlb_uniquify()

5.15.198 hangs in tlb_init() on every cold start of a TP-Link Archer C25 v1
(QCA956X). 63 cold starts, mains switched remotely, images loaded over TFTP
into RAM so the flash stayed untouched:

  5.15.198 stock             0 of 21 booted
  5.15.198 with this patch  21 of 21 booted
  6.6.144 (OpenWrt 24.10.8) 21 of 21 booted

Both 5.15.198 arms come from the same build tree and differ only by this patch.
Also reproduced on a TL-WR1043ND v2 (QCA9558).

Which boards are hit cannot be predicted from the CPU core. Unpatched 5.15.198
booted 11 of 11 cold starts on each of a TL-WDR3600 v1 (AR9344, also 74Kc), a
Ubiquiti EdgeRouter X and a Xiaomi Mi Router 4A Gigabit (both MT7621, 1004Kc).
The behaviour is deterministic per device but not per core, which fits the
mechanism: r4k_tlb_uniquify() operates on what the bootloader left in the TLB,
and that differs per board.

This reverts the call added in 5.15.190 by 35ad7e181541 ("MIPS: mm: tlb-r4k:
Uniquify TLB entries on init"), restoring 5.15.189 behaviour. The last output
before the hang comes from vfs_caches_init_early(), the next would come from
mm_init(); trap_init() sits between them and reaches r4k_tlb_uniquify() via
tlb_init() and r4k_tlb_configure().

Cold start only: the function operates on whatever the bootloader left in the
TLB - arbitrary on power-up, already uniquified after a warm reset. From the
follow-up 9f048fa48740, which is in 5.15.197 and does not suffice here: "a TLB
shutdown may occur if multiple matching entries are detected ... Given that we
don't know what entries we have been handed". Devices therefore survive any
number of sysupgrades and never come back after a power cut.

Nothing further landed in 5.15 through .203. The 6.6 line received four more
commits (231ac951faba, 43fa022b56dc, 591f030449ad, 811b3dccfb0a), the last a
rewrite depending on current_cpu_data.vmbits, VPN2_SHIFT, struct tlbent,
memblock_alloc_raw and slab_is_available - none of them present in the 5.15
file, so backporting was rejected. 35ad7e181541 addresses microAptiv/M5150,
cores we do not deploy.

Under target/linux/generic/ because tlb-r4k.c is built for every r4k-class MIPS
core: our March 2026 outage hit 57 nodes across ath79 (74Kc and 24Kc), lantiq
(34Kc) and ramips (24KEc), and no non-MIPS node at all. Since affected boards
cannot be told apart by their core, restricting the patch to one target would
be guesswork.

Drop this on Gluon 2025.1.1 or newer, whose 6.6.144 measured clean above - but
not on v2025.1, which carries 6.6.119.

--- a/arch/mips/mm/tlb-r4k.c
+++ b/arch/mips/mm/tlb-r4k.c
@@ -512,7 +512,7 @@ static int r4k_vpn_cmp(const void *a, co
  * Initialise all TLB entries with unique values that do not clash with
  * what we have been handed over and what we'll be using ourselves.
  */
-static void r4k_tlb_uniquify(void)
+static void __maybe_unused r4k_tlb_uniquify(void)
 {
 	unsigned long tlb_vpns[1 << MIPS_CONF1_TLBS_SIZE];
 	int tlbsize = current_cpu_data.tlbsize;
@@ -616,7 +616,6 @@ static void r4k_tlb_configure(void)
 	temp_tlb_entry = current_cpu_data.tlbsize - 1;
 
 	/* From this point on the ARC firmware is dead.	 */
-	r4k_tlb_uniquify();
 	local_flush_tlb_all();
 
 	/* Did I tell you that ARC SUCKS?  */
```

### Arm D im Volltext

```diff
From: Neanderfunk build environment
Subject: [PATCH] MIPS: backport the 6.6 TLB uniquification to 5.15

PROOF OF CONCEPT -- not in use. Our production patch
999-mips-tlb-r4k-no-uniquify.patch removes the call to r4k_tlb_uniquify()
instead. This one brings the 6.6 implementation over, to show what that
would cost.

Background: 35ad7e181541 ("MIPS: mm: tlb-r4k: Uniquify TLB entries on
init") entered 5.15.190 and hangs several ath79 boards on every cold
start. 9f048fa48740 followed in 5.15.197 and does not suffice: measured
0 of 21 cold starts on a TP-Link Archer C25 v1 and 0 of 20 on a
TL-WR1043ND v2, both running 5.15.198, which contains that fix. Nothing
further has landed up to 5.15.203. The 6.6 line received four more
commits and boots cleanly (21 of 21 on the C25 with 6.6.144).

The interesting part is not the copied code but the preconditions. Three
had to be met, and each one is a separate upstream change:

 1. read_c0_entryhi_64()/write_c0_entryhi_64() do not exist in 5.15.
    Added to mipsregs.h on top of the existing 64-bit accessors.

 2. memblock_free() takes a pointer only from 5.17 onwards; in 5.15 the
    function is called memblock_free_ptr(). Renamed.

 3. cpuinfo_mips.vmbits sits behind #ifdef CONFIG_64BIT in 5.15, so on
    every 32-bit board -- which is all of ours -- the field does not
    exist at all. Exposing it is not enough: nothing would fill it. 6.6
    defaults it to 31 and only probes it on 64-bit CPUs, so
    cpu_probe_vmbits() had to be taken over as well, and the R3000 path
    sets it explicitly.

Deliberately NOT taken over: the pte_offset_map()/pte_unmap() changes
around update_mmu_cache(), which are unrelated 6.6 drift.

Compile-tested for mips_24kc (ath79-generic, gcc 12.3.0): tlb-r4k.o and
cpu-probe.o build without warnings. NOT tested on hardware.

--- a/arch/mips/include/asm/cpu-info.h	2026-09-08 22:13:23.218937683 +0200
+++ b/arch/mips/include/asm/cpu-info.h	2026-09-08 22:13:03.127811155 +0200
@@ -80,9 +80,7 @@
 	int			srsets; /* Shadow register sets */
 	int			package;/* physical package number */
 	unsigned int		globalnumber;
-#ifdef CONFIG_64BIT
 	int			vmbits; /* Virtual memory size in bits */
-#endif
 	void			*data;	/* Additional data */
 	unsigned int		watch_reg_count;   /* Number that exist */
 	unsigned int		watch_reg_use_cnt; /* Usable by ptrace */
--- a/arch/mips/include/asm/mipsregs.h	2026-09-08 22:13:23.218445579 +0200
+++ b/arch/mips/include/asm/mipsregs.h	2026-09-08 22:13:03.122393496 +0200
@@ -1719,6 +1719,8 @@
 
 #define read_c0_entryhi()	__read_ulong_c0_register($10, 0)
 #define write_c0_entryhi(val)	__write_ulong_c0_register($10, 0, val)
+#define read_c0_entryhi_64()	__read_64bit_c0_register($10, 0)
+#define write_c0_entryhi_64(val) __write_64bit_c0_register($10, 0, val)
 
 #define read_c0_guestctl1()	__read_32bit_c0_register($10, 4)
 #define write_c0_guestctl1(val)	__write_32bit_c0_register($10, 4, val)
--- a/arch/mips/kernel/cpu-probe.c	2026-09-08 22:13:23.222288965 +0200
+++ b/arch/mips/kernel/cpu-probe.c	2026-09-08 22:13:03.133496044 +0200
@@ -208,11 +208,14 @@
 
 static inline void cpu_probe_vmbits(struct cpuinfo_mips *c)
 {
-#ifdef __NEED_VMBITS_PROBE
-	write_c0_entryhi(0x3fffffffffffe000ULL);
-	back_to_back_c0_hazard();
-	c->vmbits = fls64(read_c0_entryhi() & 0x3fffffffffffe000ULL);
-#endif
+	int vmbits = 31;
+
+	if (cpu_has_64bits) {
+		write_c0_entryhi_64(0x3fffffffffffe000ULL);
+		back_to_back_c0_hazard();
+		vmbits = fls64(read_c0_entryhi_64() & 0x3fffffffffffe000ULL);
+	}
+	c->vmbits = vmbits;
 }
 
 static void set_isa(struct cpuinfo_mips *c, unsigned int isa)
--- a/arch/mips/kernel/cpu-r3k-probe.c	2026-09-08 22:13:23.223856584 +0200
+++ b/arch/mips/kernel/cpu-r3k-probe.c	2026-09-08 22:13:03.138926977 +0200
@@ -160,6 +160,8 @@
 	else
 		cpu_set_nofpu_opts(c);
 
+	c->vmbits = 31;
+
 	reserve_exception_space(0, 0x400);
 }
 
--- a/arch/mips/mm/tlb-r4k.c	2026-09-08 22:13:23.216519647 +0200
+++ b/arch/mips/mm/tlb-r4k.c	2026-09-08 22:13:03.116808705 +0200
@@ -12,6 +12,8 @@
 #include <linux/init.h>
 #include <linux/sched.h>
 #include <linux/smp.h>
+#include <linux/memblock.h>
+#include <linux/minmax.h>
 #include <linux/mm.h>
 #include <linux/hugetlb.h>
 #include <linux/export.h>
@@ -23,6 +25,7 @@
 #include <asm/hazards.h>
 #include <asm/mmu_context.h>
 #include <asm/tlb.h>
+#include <asm/tlbdebug.h>
 #include <asm/tlbmisc.h>
 
 extern void build_tlb_refill_handler(void);
@@ -500,81 +503,266 @@
 __setup("ntlb=", set_ntlb);
 
 
-/* Comparison function for EntryHi VPN fields.  */
-static int r4k_vpn_cmp(const void *a, const void *b)
+/* The start bit position of VPN2 and Mask in EntryHi/PageMask registers.  */
+#define VPN2_SHIFT 13
+
+/* Read full EntryHi even with CONFIG_32BIT.  */
+static inline unsigned long long read_c0_entryhi_native(void)
+{
+	return cpu_has_64bits ? read_c0_entryhi_64() : read_c0_entryhi();
+}
+
+/* Write full EntryHi even with CONFIG_32BIT.  */
+static inline void write_c0_entryhi_native(unsigned long long v)
 {
-	long v = *(unsigned long *)a - *(unsigned long *)b;
-	int s = sizeof(long) > sizeof(int) ? sizeof(long) * 8 - 1: 0;
-	return s ? (v != 0) | v >> s : v;
+	if (cpu_has_64bits)
+		write_c0_entryhi_64(v);
+	else
+		write_c0_entryhi(v);
 }
 
+/* TLB entry state for uniquification.  */
+struct tlbent {
+	unsigned long long wired:1;
+	unsigned long long global:1;
+	unsigned long long asid:10;
+	unsigned long long vpn:51;
+	unsigned long long pagesz:5;
+	unsigned long long index:14;
+};
+
 /*
- * Initialise all TLB entries with unique values that do not clash with
- * what we have been handed over and what we'll be using ourselves.
+ * Comparison function for TLB entry sorting.  Place wired entries first,
+ * then global entries, then order by the increasing VPN/ASID and the
+ * decreasing page size.  This lets us avoid clashes with wired entries
+ * easily and get entries for larger pages out of the way first.
+ *
+ * We could group bits so as to reduce the number of comparisons, but this
+ * is seldom executed and not performance-critical, so prefer legibility.
  */
-static void r4k_tlb_uniquify(void)
+static int r4k_entry_cmp(const void *a, const void *b)
 {
-	unsigned long tlb_vpns[1 << MIPS_CONF1_TLBS_SIZE];
-	int tlbsize = current_cpu_data.tlbsize;
-	int start = num_wired_entries();
-	unsigned long vpn_mask;
-	int cnt, ent, idx, i;
-
-	vpn_mask = GENMASK(cpu_vmbits - 1, 13);
-	vpn_mask |= IS_ENABLED(CONFIG_64BIT) ? 3ULL << 62 : 1 << 31;
+	struct tlbent ea = *(struct tlbent *)a, eb = *(struct tlbent *)b;
 
-	htw_stop();
+	if (ea.wired > eb.wired)
+		return -1;
+	else if (ea.wired < eb.wired)
+		return 1;
+	else if (ea.global > eb.global)
+		return -1;
+	else if (ea.global < eb.global)
+		return 1;
+	else if (ea.vpn < eb.vpn)
+		return -1;
+	else if (ea.vpn > eb.vpn)
+		return 1;
+	else if (ea.asid < eb.asid)
+		return -1;
+	else if (ea.asid > eb.asid)
+		return 1;
+	else if (ea.pagesz > eb.pagesz)
+		return -1;
+	else if (ea.pagesz < eb.pagesz)
+		return 1;
+	else
+		return 0;
+}
 
-	for (i = start, cnt = 0; i < tlbsize; i++, cnt++) {
-		unsigned long vpn;
+/*
+ * Fetch all the TLB entries.  Mask individual VPN values retrieved with
+ * the corresponding page mask and ignoring any 1KiB extension as we'll
+ * be using 4KiB pages for uniquification.
+ */
+static void __ref r4k_tlb_uniquify_read(struct tlbent *tlb_vpns, int tlbsize)
+{
+	int start = num_wired_entries();
+	unsigned long long vpn_mask;
+	bool global;
+	int i;
+
+	vpn_mask = GENMASK(current_cpu_data.vmbits - 1, VPN2_SHIFT);
+	vpn_mask |= cpu_has_64bits ? 3ULL << 62 : 1 << 31;
+
+	for (i = 0; i < tlbsize; i++) {
+		unsigned long long entryhi, vpn, mask, asid;
+		unsigned int pagesz;
 
 		write_c0_index(i);
 		mtc0_tlbr_hazard();
 		tlb_read();
 		tlb_read_hazard();
-		vpn = read_c0_entryhi();
-		vpn &= vpn_mask & PAGE_MASK;
-		tlb_vpns[cnt] = vpn;
 
-		/* Prevent any large pages from overlapping regular ones.  */
-		write_c0_pagemask(read_c0_pagemask() & PM_DEFAULT_MASK);
-		mtc0_tlbw_hazard();
-		tlb_write_indexed();
-		tlbw_use_hazard();
+		global = !!(read_c0_entrylo0() & ENTRYLO_G);
+		entryhi = read_c0_entryhi_native();
+		mask = read_c0_pagemask();
+
+		asid = entryhi & cpu_asid_mask(&current_cpu_data);
+		vpn = (entryhi & vpn_mask & ~mask) >> VPN2_SHIFT;
+		pagesz = ilog2((mask >> VPN2_SHIFT) + 1);
+
+		tlb_vpns[i].global = global;
+		tlb_vpns[i].asid = global ? 0 : asid;
+		tlb_vpns[i].vpn = vpn;
+		tlb_vpns[i].pagesz = pagesz;
+		tlb_vpns[i].wired = i < start;
+		tlb_vpns[i].index = i;
 	}
+}
 
-	sort(tlb_vpns, cnt, sizeof(tlb_vpns[0]), r4k_vpn_cmp, NULL);
+/*
+ * Write unique values to all but the wired TLB entries each, using
+ * the 4KiB page size.  This size might not be supported with R6, but
+ * EHINV is mandatory for R6, so we won't ever be called in that case.
+ *
+ * A sorted table is supplied with any wired entries at the beginning,
+ * followed by any global entries, and then finally regular entries.
+ * We start at the VPN and ASID values of zero and only assign user
+ * addresses, therefore guaranteeing no clash with addresses produced
+ * by UNIQUE_ENTRYHI.  We avoid any VPN values used by wired or global
+ * entries, by increasing the VPN value beyond the span of such entry.
+ *
+ * When a VPN/ASID clash is found with a regular entry we increment the
+ * ASID instead until no VPN/ASID clash has been found or the ASID space
+ * has been exhausted, in which case we increase the VPN value beyond
+ * the span of the largest clashing entry.
+ *
+ * We do not need to be concerned about FTLB or MMID configurations as
+ * those are required to implement the EHINV feature.
+ */
+static void __ref r4k_tlb_uniquify_write(struct tlbent *tlb_vpns, int tlbsize)
+{
+	unsigned long long asid, vpn, vpn_size, pagesz;
+	int widx, gidx, idx, sidx, lidx, i;
 
-	write_c0_pagemask(PM_DEFAULT_MASK);
+	vpn_size = 1ULL << (current_cpu_data.vmbits - VPN2_SHIFT);
+	pagesz = ilog2((PM_4K >> VPN2_SHIFT) + 1);
+
+	write_c0_pagemask(PM_4K);
 	write_c0_entrylo0(0);
 	write_c0_entrylo1(0);
 
-	idx = 0;
-	ent = tlbsize;
-	for (i = start; i < tlbsize; i++)
-		while (1) {
-			unsigned long entryhi, vpn;
+	asid = 0;
+	vpn = 0;
+	widx = 0;
+	gidx = 0;
+	for (sidx = 0; sidx < tlbsize && tlb_vpns[sidx].wired; sidx++)
+		;
+	for (lidx = sidx; lidx < tlbsize && tlb_vpns[lidx].global; lidx++)
+		;
+	idx = gidx = sidx + 1;
+	for (i = sidx; i < tlbsize; i++) {
+		unsigned long long entryhi, vpn_pagesz = 0;
 
-			entryhi = UNIQUE_ENTRYHI(ent);
-			vpn = entryhi & vpn_mask & PAGE_MASK;
+		while (1) {
+			if (WARN_ON(vpn >= vpn_size)) {
+				dump_tlb_all();
+				/* Pray local_flush_tlb_all() will cope.  */
+				return;
+			}
 
-			if (idx >= cnt || vpn < tlb_vpns[idx]) {
-				write_c0_entryhi(entryhi);
-				write_c0_index(i);
-				mtc0_tlbw_hazard();
-				tlb_write_indexed();
-				ent++;
-				break;
-			} else if (vpn == tlb_vpns[idx]) {
-				ent++;
-			} else {
+			/* VPN must be below the next wired entry.  */
+			if (widx < sidx && vpn >= tlb_vpns[widx].vpn) {
+				vpn = max(vpn,
+					  (tlb_vpns[widx].vpn +
+					   (1ULL << tlb_vpns[widx].pagesz)));
+				asid = 0;
+				widx++;
+				continue;
+			}
+			/* VPN must be below the next global entry.  */
+			if (gidx < lidx && vpn >= tlb_vpns[gidx].vpn) {
+				vpn = max(vpn,
+					  (tlb_vpns[gidx].vpn +
+					   (1ULL << tlb_vpns[gidx].pagesz)));
+				asid = 0;
+				gidx++;
+				continue;
+			}
+			/* Try to find a free ASID so as to conserve VPNs.  */
+			if (idx < tlbsize && vpn == tlb_vpns[idx].vpn &&
+			    asid == tlb_vpns[idx].asid) {
+				unsigned long long idx_pagesz;
+
+				idx_pagesz = tlb_vpns[idx].pagesz;
+				vpn_pagesz = max(vpn_pagesz, idx_pagesz);
+				do
+					idx++;
+				while (idx < tlbsize &&
+				       vpn == tlb_vpns[idx].vpn &&
+				       asid == tlb_vpns[idx].asid);
+				asid++;
+				if (asid > cpu_asid_mask(&current_cpu_data)) {
+					vpn += vpn_pagesz;
+					asid = 0;
+					vpn_pagesz = 0;
+				}
+				continue;
+			}
+			/* VPN mustn't be above the next regular entry.  */
+			if (idx < tlbsize && vpn > tlb_vpns[idx].vpn) {
+				vpn = max(vpn,
+					  (tlb_vpns[idx].vpn +
+					   (1ULL << tlb_vpns[idx].pagesz)));
+				asid = 0;
 				idx++;
+				continue;
 			}
+			break;
 		}
 
+		entryhi = (vpn << VPN2_SHIFT) | asid;
+		write_c0_entryhi_native(entryhi);
+		write_c0_index(tlb_vpns[i].index);
+		mtc0_tlbw_hazard();
+		tlb_write_indexed();
+
+		tlb_vpns[i].asid = asid;
+		tlb_vpns[i].vpn = vpn;
+		tlb_vpns[i].pagesz = pagesz;
+
+		asid++;
+		if (asid > cpu_asid_mask(&current_cpu_data)) {
+			vpn += 1ULL << pagesz;
+			asid = 0;
+		}
+	}
+}
+
+/*
+ * Initialise all TLB entries with unique values that do not clash with
+ * what we have been handed over and what we'll be using ourselves.
+ */
+static void __ref r4k_tlb_uniquify(void)
+{
+	int tlbsize = current_cpu_data.tlbsize;
+	bool use_slab = slab_is_available();
+	phys_addr_t tlb_vpn_size;
+	struct tlbent *tlb_vpns;
+
+	tlb_vpn_size = tlbsize * sizeof(*tlb_vpns);
+	tlb_vpns = (use_slab ?
+		    kmalloc(tlb_vpn_size, GFP_ATOMIC) :
+		    memblock_alloc_raw(tlb_vpn_size, sizeof(*tlb_vpns)));
+	if (WARN_ON(!tlb_vpns))
+		return; /* Pray local_flush_tlb_all() is good enough. */
+
+	htw_stop();
+
+	r4k_tlb_uniquify_read(tlb_vpns, tlbsize);
+
+	sort(tlb_vpns, tlbsize, sizeof(*tlb_vpns), r4k_entry_cmp, NULL);
+
+	r4k_tlb_uniquify_write(tlb_vpns, tlbsize);
+
+	write_c0_pagemask(PM_DEFAULT_MASK);
+
 	tlbw_use_hazard();
 	htw_start();
 	flush_micro_tlb();
+	if (use_slab)
+		kfree(tlb_vpns);
+	else
+		memblock_free_ptr(tlb_vpns, tlb_vpn_size);
 }
 
 /*
```

## 11. Ergebnis

`patches/999-mips-tlb-r4k-no-uniquify.patch` nimmt den Aufruf zurück und
stellt das Verhalten bis 5.15.189 wieder her. Begründung und Messwerte stehen
im Kopf der Patchdatei. Über beide betroffenen Geräte hinweg sind das
**0 von 41** Kaltstarts ungepatcht gegen **41 von 41** gepatcht. Beim Umstieg auf Gluon 2025.1.1 oder neuer kann er weg,
siehe Kapitel 4.4 in `migration-2025.1-targets.md`.
