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
      Betroffen gesehen: TP-Link Archer C6 v2 (tplink_archer-c6-v2,
      ath79-generic).
      Wahrscheinliche Ursache: primary_addrs in
      package/gluon-core/luasrc/lib/gluon/upgrade/010-primary-mac fuehrt
      Bloecke fuer interface('lan'), interface('wan') und phy(1), danach als
      Auffangnetz "{phy(0), {{}}}" - matches everything. Der C6 v2 steht in
      keiner Geraeteliste, weder unter 2023.2 noch unter 2025.1, bekommt also
      die MAC des ersten WLAN-Radios. Der Aufkleber nennt dagegen die
      Ethernet-MAC, und der Abstand zwischen beiden betraegt bei TP-Link
      typisch 4. Warum es unter 2021.x stimmte, duerfte an der geaenderten
      phy-Nummerierung ab OpenWrt 22.03 liegen.
      Am Geraet zu messen:
        uci -q get gluon.core.primary_mac
        cat /sys/class/ieee80211/phy0/macaddress
        cat /sys/class/ieee80211/phy1/macaddress
        cat /sys/class/net/eth0/address
      Stimmt primary_mac mit phy0 ueberein und weicht vom Aufkleber ab, ist es
      das. Behebung waere ein Eintrag fuer den C6 v2 im passenden Block.
- [ ] nil-Guards fuer die Statusseite nach v2023.2.x zurueckportieren. Das ist
      kein Schoenheitsfehler, sondern ein latenter Absturz in der laufenden
      Firmware: statuspage-moredetails.patch schreibt auf diesem Branch
        <dd><%| nodeinfo.network.mesh.bat0.interfaces.other[1] %></dd>
      ohne jede Pruefung. Fehlt ein Zwischenglied - mesh, bat0, interfaces oder
      other -, ist das kein leeres Feld, sondern ein Lua-Fehler ("attempt to
      index a nil value"), und die Statusseite rendert gar nicht mehr. Betroffen
      waere ein Knoten, dessen einziges Mesh der VPN-Tunnel ist: kein
      WLAN-Mesh, kein LAN-Mesh. Dieselbe Luecke hat die Tunnel-MAC-Zeile: sie
      prueft zwar auf .tunnel und .tunnel[1], nicht aber auf die Zwischenglieder.
      Drei weitere Zeilen (ImageName, Gluon Version, Sitecode) wuerden bloss
      "nil" anzeigen, was Nutzer verwirrt.
      Vorlage: Commit b228e37 auf v2025.1.x.
- [ ] Offline-SSID-Anzeige nach v2023.2.x zurueckportieren. Auf dem Branch
      v2025.1.x zeigt die Statusseite hinter der Radio-Tabelle, ob der
      neanderfunk-ssid-changer den Knoten zuletzt als offline eingestuft hat
      (/tmp/ssid-changer-offline, 0 oder 1), siehe patches/statuspage-ssid.patch
      dort. Hier muss der Teil in einen eigenen Patch, weil statuspage-ssid.patch
      auf 2023.2.x noch SSID und HT-Modus liefert - die kommen erst mit 2025.1
      von Upstream.
