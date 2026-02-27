#!/bin/bash
# 物理审计：粉碎无关设备，保留官方 MK 框架，禁用 EOF，锁定救砖逻辑

# 1. 物理重写 mt7981.mk (原文照抄全局变量，锁定 eMMC 救砖定义)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. 物理注入 5.4 内核 DTS (物理对位您的 eMMC 128GB 硬件)
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 3. 物理重构驱动 (粉碎旧记忆，修复 mac80211 在 5.4 内核下的编译熔断)
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
mv package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/mac80211
rm -rf package/kernel/mac80211_tmp

# 4. 基础 IP 物理对齐 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "U-Boot 救砖 MK 环境已物理就绪，禁用 EOF。"
