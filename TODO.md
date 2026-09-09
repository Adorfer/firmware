feel free to add things

- [x] patch sites for diff. communities based on a template
- [x] build all targets
- [x] c-respondd
- [ ] switch for ssh keys
- [ ] ch13 / ch5 relchain (additional to ch9)
- [ ] mi4ag-migration.patch: die ERX-Ausnahme in fwtool.sh prueft auf
      "ubnt-erx", das Geraet meldet aber "ubnt,edgerouter-x" (Name aus
      OpenWrt 19.07). Die Ausnahme ist damit seit ihrer Einfuehrung
      wirkungslos. Betroffen sind Knoten, deren compat_version noch auf 1.0
      steht (nie gesetzt) und die ein 1.1-Image bekommen: der Autoupdater
      flasht konfigurationserhaltend, und genau das weist die
      Minor-Pruefung ab. Bei 1.1 -> 1.1 faellt es nicht auf. Vor dem Fix
      pruefen, ob es ueberhaupt noch Knoten mit 1.0 gibt - sonst kann die
      Ausnahme ersatzlos weg. Befund vom 09.09.2026, siehe
      docs/erx-migration-howto.md.
- [ ] primary-mac stimmt nach "sysupgrade -n" nicht mit dem Etikett ueberein.
      Unter Gluon 2021.x war es korrekt, seit 2023.2.x nicht mehr; der Versatz
      betraegt mehr als ein Byte, etwa 4 hoeher oder tiefer. Da die primaere
      MAC die node_id bestimmt, findet danach niemand sein Geraet anhand des
      Aufklebers wieder. Beispielgeraete werden noch gesucht (adorfer).
      Ansatz: primary_addrs in
      package/gluon-core/luasrc/lib/gluon/upgrade/010-primary-mac zerfaellt in
      die Bloecke interface('lan'), interface('wan') und phy(1) und wird in
      dieser Reihenfolge abgearbeitet - der erste Treffer gewinnt. Steht ein
      Geraet im falschen Block oder in keinem, greift eine andere Quelle, und
      benachbarte Interface-MACs liegen nur wenige Zaehler auseinander. Zu
      pruefen: was sich zwischen 2021.x und 2023.2 an dieser Datei und an der
      Fallback-Regel geaendert hat.
