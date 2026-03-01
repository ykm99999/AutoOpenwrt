#!/bin/bash
# 物理审计：物理接管 U-Boot 仓库，粉碎 mac80211 依赖链，锁定 5.4 内核

# 1. 物理重写 mt7981.mk (原文照抄官方框架)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. U-Boot 源码物理重定向 (物理接管 sl3000-uboot-base 分支)
# 审计：物理改写 Makefile，确保救砖 FIP 编译时拉取您的私有仓库
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    # 物理抹除旧哈希，防止下载校验熔断
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MAKEFILE"
fi

# 3. 彻底粉碎 Mac80211 报错 (对齐 5.4 内核 API)
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp
# 物理阻断 6.6.15 幻像
sed -i 's/^PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_SOURCE:=.*/PKG_SOURCE:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_HASH:=.*/PKG_HASH:=/g' package/kernel/mac80211/Makefile

# 4. 物理注入 5.4 内核专用的 DTS
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 5. IP 物理对齐 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "物理接管完成：U-Boot 仓库已重定向至 ykm99999/66。"
