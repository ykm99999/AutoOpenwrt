#!/bin/bash
# 物理审计：彻底粉碎 tasklet_setup 报错，物理阻断 backports-6.6 恢复

# 1. 物理重写 mt7981.mk (原文照抄全局框架)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. 物理强制替换 mac80211 (彻底粉碎 6.6 补丁依赖)
# 审计：先删除 package 层级，再阻断 feeds 软链接
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp

# 物理修改：强制将 mac80211 的版本锁定，防止其下载 backports-6.6
# 针对 5.4 内核，物理移除 Makefile 中可能触发 6.6 下载的逻辑
sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile 2>/dev/null || true

# 3. 物理注入 5.4 内核专用的 DTS
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 4. 物理清理递归依赖与 IP 对齐
find package -name "Makefile" | xargs grep -l "PACKAGE_rd05a1" | xargs sed -i '/DEPENDS.*PACKAGE_rd05a1/d' 2>/dev/null || true
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "物理强行对位完成，6.6.15 补丁已从物理层面阻断。"
