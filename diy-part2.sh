#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
#

# 1. 物理修复：在 mt7981.mk 中确保激活 sl_3000-emmc 设备
sed -i 's/# TARGET_DEVICES += sl_3000-emmc/TARGET_DEVICES += sl_3000-emmc/g' target/linux/mediatek/image/mt7981.mk

# 2. 彻底解决：不再物理删除 Makefile 行（防止语法报错），改用逻辑屏蔽
# 强制通过 .config 锁定编译目标，防止 defconfig 自动拉起 MIPS 设备
echo "CONFIG_PACKAGE_uboot-mediatek-mt7620_mt7530_rfb=n" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7621_rfb=n" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7628_rfb=n" >> .config

# 3. 物理注入：开启 MT7981 专用救砖驱动与引导构建
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl_3000-emmc_UBOOT_DA=y" >> .config
echo "CONFIG_MTK_DOWNLOAD_AGENT=y" >> .config
