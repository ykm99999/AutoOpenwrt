#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
#

# 1. 物理修复：在 mt7981.mk 中确保激活 sl_3000-emmc 设备
sed -i 's/# TARGET_DEVICES += sl_3000-emmc/TARGET_DEVICES += sl_3000-emmc/g' target/linux/mediatek/image/mt7981.mk

# 2. 彻底解决：物理屏蔽所有非 A53 架构的 U-Boot 变体，防止 aarch64-gcc 报错
sed -i '/mt7620/d' package/boot/uboot-mediatek/Makefile
sed -i '/mt7621/d' package/boot/uboot-mediatek/Makefile
sed -i '/mt7628/d' package/boot/uboot-mediatek/Makefile

# 3. 物理注入：开启完整固件及 DA 驱动构建宏
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl_3000-emmc_UBOOT_DA=y" >> .config
echo "CONFIG_MTK_DOWNLOAD_AGENT=y" >> .config
