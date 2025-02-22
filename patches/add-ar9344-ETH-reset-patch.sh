#!/bin/bash
echo $PWD 

  echo "Applying patches for TL-WR3600/WR4300 reboot patches on openwrt"
  pushd openwrt
  [ -f target/linux/ath79/patches-5.15/101-reset-ath79-reset-ETH-switch-for-AR9344.patch ] && echo "target/linux/ath79/patches-5.15/101-reset-ath79-reset-ETH-switch-for-AR9344.patch exists, skipping copy." || cp ../../patches/101-reset-ath79-reset-ETH-switch-for-AR9344.patch target/linux/ath79/patches-5.15/101-reset-ath79-reset-ETH-switch-for-AR9344.patch
  popd