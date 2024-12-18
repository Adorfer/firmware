#!/bin/bash
echo $PWD 

  echo "Copying patch: Silence AirtimeMonitor-Warnings in logs"
  [ -f openwrt/package/kernel/mac80211/patches/subsys/999-silence-missing-rate.patch ] && echo "target/linux/ramips/patches-5.10/412-mtd-spi-nor-add-support-for-zbit-zb25vq128.patch exists, skipping copy." || cp ../999-silence-missing-rate.patch openwrt/package/kernel/mac80211/patches/subsys/999-silence-missing-rate.patch

