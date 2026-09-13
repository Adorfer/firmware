# squashfs-Blockgroesse je Geraet fuer das Target ath79, in KiB.
#
# Wird von patches/squashfs-blocksize-per-device.sh nach
# openwrt/target/linux/ath79/image/squashfs-blocksize.mk kopiert und dort von
# include/image.mk gelesen (openwrt-squashfs-blocksize-per-device.patch).
# Schluessel ist der OpenWrt-Geraetename (zweites Argument von device() in
# gluon/targets/ath79-*), nicht der Gluon-Name. Ohne Eintrag gilt die
# Target-Vorgabe CONFIG_TARGET_SQUASHFS_BLOCK_SIZE (Gluon: 256).
#
# Kandidaten: die 64-MB-Geraete mit zwei Radios (lowmem_dualradio in
# templates/common/image-customization.lua). Einschalten durch Entfernen des
# "#". Dahinter: freies Overlay mit 256 -> 64 KiB (lokaler Vergleichsbau
# 12.09.2026, scratch/2026-09-12-squashfs64/vergleich-lokal-256-vs-64.txt).
#
# Messung am Archer C25 (12.09.2026, je 1 h ruhig, alle RAM-Entlastungen):
# 256 KiB 59 Refaults / MemAvailable 2,8 MB, 64 KiB 0 / 3,5 MB. Tendenz, nicht
# belastbar; geparkt, bis Felddaten (respondd system: Refaults) Bedarf zeigen.
#
# Keine Kommentare hinter einer Zuweisung: make nimmt die Leerzeichen vor dem
# "#" in den Wert auf.

# freies Overlay 8896 -> 8640 kB
#SQUASHFS_BLOCKSIZE/avm_fritz1750e := 64

# freies Overlay 1536 -> 1216 kB
#SQUASHFS_BLOCKSIZE/tplink_archer-c2-v3 := 64

# freies Overlay 1536 -> 1216 kB
#SQUASHFS_BLOCKSIZE/tplink_archer-c25-v1 := 64

# freies Overlay 1344 -> 1088 kB
#SQUASHFS_BLOCKSIZE/tplink_archer-c58-v1 := 64

# freies Overlay 1216 ->  896 kB
#SQUASHFS_BLOCKSIZE/tplink_archer-c60-v1 := 64

# freies Overlay 1408 -> 1152 kB
#SQUASHFS_BLOCKSIZE/tplink_archer-d50-v1 := 64

# freies Overlay  960 ->  704 kB
#SQUASHFS_BLOCKSIZE/tplink_tl-wr902ac-v1 := 64

# freies Overlay 1728 -> 1472 kB
#SQUASHFS_BLOCKSIZE/dlink_dir-825-b1 := 64

# freies Overlay 1600 -> 1344 kB
#SQUASHFS_BLOCKSIZE/netgear_wndr3700 := 64

# freies Overlay 7488 -> 7104 kB
#SQUASHFS_BLOCKSIZE/netgear_wndr3700-v2 := 64
