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
