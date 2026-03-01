#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# ======= 添加：救砖全家桶 U-Boot 仓库锁定 =======
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    sed -i "s/UBOOT_TARGETS := .*/UBOOT_TARGETS := mt7981_sl3000_emmc/g" "$UBOOT_MAKEFILE"
fi

# 物理注入 DTS 和 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
[ -f $GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts ] && cp -f $GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts
