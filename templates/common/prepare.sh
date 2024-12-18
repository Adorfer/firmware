#!/bin/bash
# git apply $(dirname $0)/keepradiochannel.diff
# echo "CONFIG_PATA_ATIIXP=y" >> openwrt/target/linux/x86/generic/config-default
 
#cp ../patches/sysupgrade ./openwrt/package/base-files/files/sbin/sysupgrade
#chmod +x ./openwrt/package/base-files/files/sbin/sysupgrade

#pushd ../gluon ; git am ../patches/0001-*; popd ; # apply 0001-enumerated patches automaticylly
pushd ../gluon ; ../patches/fix-respondd-rsk.sh; popd  # change respondd listener address to gluon 2016.x value
pushd ../gluon ; ../patches/mi4apatch.sh; popd  # make Mi4Agigabit upgradable
pushd ../gluon ; ../patches/add-totolink-x5000r.sh; popd  # adding Totolink X5000R
pushd ../gluon ; ../patches/additionaltargets.sh; popd  # add several targets from openwrt
pushd ../gluon ; ../patches/add-cellular.sh; popd  # add cellular modems zte
pushd ../gluon ; ../patches/interfaces-patch.sh  ; popd  # change primary macs
pushd ../gluon ; ../patches/statuspage-moredetails.sh  ; popd  # more details in status-page
#pushd ../gluon ; ../patches/ignore-preservechannels-for-outdoormode.sh ; popd # correct handling of outdoor-devices (enable auto-channel)
exit 0;

