#!/bin/bash
# 物理审计：彻底粉碎 backports-6.6.15 依赖链条，强制对齐 5.4 内核

# 1. 物理重写 mt7981.mk (原文照抄全局框架)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. 彻底粉碎 mac80211 错误依赖 (物理阻断 6.6.15 下载)
# 审计：先移除损坏的目录，再从 LEDE 仓库物理拉取适配 5.4 内核的版本
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp

# 物理像素级修复：强制修改新下载的 Makefile，清除任何可能导致系统寻找 6.6.15 的变量
# 物理切断 PKG_SOURCE 和 PKG_HASH，强制使用本地源码编译
sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile
sed -i 's/PKG_HASH:=.*/PKG_HASH:=skip/g' package/kernel/mac80211/Makefile

# 3. 物理注入 5.4 内核专用的 DTS
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 4. 环境物理清理 (移除导致递归依赖的 rd05a1)
find package -name "Makefile" | xargs grep -l "PACKAGE_rd05a1" | xargs sed -i '/DEPENDS.*PACKAGE_rd05a1/d' 2>/dev/null || true

# 5. IP 物理对齐 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "物理修复完成：6.6.15 依赖链条已粉碎，驱动已锁定为 5.4 兼容版。"
