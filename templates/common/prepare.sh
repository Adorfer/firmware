#!/bin/bash
# git apply $(dirname $0)/keepradiochannel.diff
# echo "CONFIG_PATA_ATIIXP=y" >> openwrt/target/linux/x86/generic/config-default
 
#cp ../patches/sysupgrade ./openwrt/package/base-files/files/sbin/sysupgrade
#chmod +x ./openwrt/package/base-files/files/sbin/sysupgrade

#pushd ../gluon ; git am ../patches/0001-*; popd ; # apply 0001-enumerated patches automaticylly
pushd ../gluon ; ../patches/fix-respondd-rsk.sh; 			popd  # change respondd listener address to gluon 2016.x value
pushd ../gluon ; ../patches/mi4apatch.sh; 				popd  # make Mi4Agigabit upgradable
pushd ../gluon ; ../patches/add-totolink-x5000r.sh;	 		popd  # adding Totolink X5000R
pushd ../gluon ; ../patches/add-mercusys-mr90x.sh;	 		popd  # adding MERCUSYS MR90X
pushd ../gluon ; ../patches/add-nanopi-r2c.sh; 				popd  # adding FriendlyElec Nanopi_R2C
pushd ../gluon ; ../patches/add-cudy-3000.sh; 				popd  # adding Cudy 3000 series to the mediatek filogic target
pushd ../gluon ; ../patches/additionaltargets.sh; 			popd  # add several targets from openwrt
pushd ../gluon ; ../patches/add-cellular.sh; 				popd  # add cellular modems zte
#pushd ../gluon ; ../patches/add-mt7915e-try.sh; 			popd  # [PATCH 1/2] mt76: include fixes for MT7603 / MT7612 -- deaktiviert: patches/mt7915e-try.patch existiert nicht (war nie im Repo)
#pushd ../gluon ; ../patches/mt7915-filogic-syncpowersave-patch.sh; 	popd  # patches/openwrt/0013-wifi-mt76-mt7915-sync-power-save-state-with-WA.patch
pushd ../gluon ; ../patches/interface-role-migration21.sh; 		popd  # 2021-migration: interfaces with client-network
pushd ../gluon ; ../patches/interfaces-patch.sh; 			popd  # change primary macs
pushd ../gluon ; ../patches/patch-gluon-makefiles.sh; 			popd  # change primary macs
pushd ../gluon ; ../patches/statuspage-moredetails.sh; 			popd  # more details in status-page
pushd ../gluon ; ../patches/statuspage-ssid.sh; 			popd  # SSID und htmode je Radio (Backport aus Gluon v2025.1)
pushd ../gluon ; ../patches/statuspage-hwdetails.sh; 			popd  # CPU-Typ und Kernzahl auf der Statusseite

#pushd ../gluon ; ../patches/airtime-logsilience.sh; 			popd  # top airtime-monitor from spamming logread

#pushd ../gluon ; ../patches/ignore-preservechannels-for-outdoormode.sh ; popd # correct handling of outdoor-devices (enable auto-channel)
exit 0;

