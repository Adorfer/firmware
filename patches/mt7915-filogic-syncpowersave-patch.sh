#!/bin/bash
echo $PWD 
  echo "Applying patches for on gluon wifi: mt76: mt7915: sync power save state with WA"
  [ -f patches/openwrt/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch ] && echo "gluon/patches/openwrt/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch exists, skipping copy." || cp ../patches/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch patches/openwrt/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch 
