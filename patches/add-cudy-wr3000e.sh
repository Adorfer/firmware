#!/bin/bash
echo $PWD 

  echo "Applying patches for mediatek-filogic/cudy-wr3000e on gluon"
  patchfile="../patches/add-cudy-wr3000e-gluon.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  grep 'wr3000e' targets/mediatek-filogic

  cd openwrt 
  patchfile="../../patches/add-cudy-wr3000e-openwrt.patch"
  if ! patch -R -p1 -s -f --ignore-whitespace --dry-run <$patchfile &>/dev/null; then
    patch -p1 --ignore-whitespace <$patchfile
   fi
  grep  'wr3000e' target/linux/mediatek/image/filogic.mk


#[ -f target/linux/mediatek/dts/mt7981b-cudy-wr3000e-v1.dts ] && echo "target/linux/mediatek/dts/mt7981b-cudy-wr3000e-v1.dts exists, skipping copy." || cp ../../patches/XIAOMI-MIR4A-GIGABIT.dts target/linux/mediatek/dts/mt7981b-cudy-wr3000e-v1.dts
#[ -f target/linux/mediatek/dts/mt7981b-cudy-wr3000-nand.dtsi ] && echo "target/linux/mediatek/dts/mt7981b-cudy-wr3000-nand.dtsi exists, skipping copy." || cp ../../patches/XIAOMI-MIR4A-GIGABIT.dts target/linux/mediatek/dts/mt7981b-cudy-wr3000-nand.dtsi
