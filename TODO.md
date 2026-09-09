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
- [ ] Beim naechsten Kernelsprung (6.12 oder neuer) den MT7530-EEE-Fix
      mitnehmen. Kernel 6.6.144 ist NICHT betroffen: mtk_gephy_config_init()
      in drivers/net/phy/mediatek-ge.c setzt MDIO_AN_EEE_ADV noch selbst auf 0,
      und mt7530_phy_config_init() laeuft da hindurch. Entfernt wurde das erst
      durch af3b4b0e59de ("net: phy: mediatek-ge: do not disable EEE
      advertisement"), das in 6.6.144 nicht enthalten ist.
      Symptom danach: an einem Kabel mit nur zwei belegten Adernpaaren, wenn
      beide Seiten Gigabit werben, scheitert das 1000BASE-T-Training und der
      Port laeuft in eine Schleife, statt auf 100 MBit zurueckzufallen - kein
      Link, kein DHCP. Heute ist derselbe Kabelfehler gutartig: der Link faellt
      sauber auf 100 MBit, der Knoten bleibt erreichbar. Betrifft alle
      MT7621-Geraete, der ERX wird in den Berichten namentlich genannt.
      Fix: openwrt/openwrt PR 25058 (ersetzt PR 22647), setzt im PHY-Treiber an
      und zielt auf pending-6.18. Auf 6.6 hiesse der Treiber mediatek-ge.c
      statt mediatek/mtk-ge.c, und phy_disable_eee() gibt es dort noch nicht -
      ein Rueckport waere also Handarbeit, ist aber solange unnoetig, wie die
      alte Zeile im Baum steht.
      Gegenprobe am Geraet steht aus: 2-Paar-Kabel an einen Gigabit-Port des
      ERX, erwartet wird ein sauberer 100-MBit-Link.
