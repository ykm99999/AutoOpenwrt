#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 物理修复：在 MT7981.mk 中确保激活 sl_3000-emmc 设备
sed -i 's/# TARGET_DEVICES += sl_3000-emmc/TARGET_DEVICES += sl_3000-emmc/g' target/linux/mediatek/image/mt7981.mk

# 物理注入：开启 MT7981 专用 DA (Download Agent) 与 U-Boot 构建支持
echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl_3000-emmc_UBOOT=y" >> .config
echo "CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7981_DEVICE_sl_3000-emmc_UBOOT_DA=y" >> .config
echo "CONFIG_MTK_DOWNLOAD_AGENT=y" >> .config
