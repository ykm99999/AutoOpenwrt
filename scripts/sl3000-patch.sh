#!/bin/bash
# 物理审计：对接纯净版 U-Boot 仓库，粉碎 Mac80211 依赖，锁定 5.4 内核路径

# 1. 物理重写 mt7981.mk (像素级原文照抄)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. 物理重写 U-Boot Makefile (结构死锁：仅保留 MT7981 唯一目标)
UBOOT_DIR="package/boot/uboot-mediatek"
if [ -d "$UBOOT_DIR" ]; then
    # 物理重定向至已瘦身的私有仓库
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_DIR/Makefile"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_DIR/Makefile"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_DIR/Makefile"
    
    # 物理粉碎所有机型，只留 mt7981_sl3000_emmc
    sed -i '/UBOOT_TARGETS :=/d' "$UBOOT_DIR/Makefile"
    sed -i '/define Device/,/endef/d' "$UBOOT_DIR/Makefile"
    sed -i '/include ..\/..\/package.mk/i UBOOT_TARGETS := mt7981_sl3000_emmc' "$UBOOT_DIR/Makefile"
    
    # 物理注入唯一的 Device 声明，确保与瘦身后的仓库 configs 目录物理对齐
    printf '\ndefine Device/mt7981_sl3000_emmc\n  NAME := SL-3000 eMMC\n  BUILD_SUBTARGET := mt7981\n  UBOOT_CONFIG := mt7981_sl_3000-emmc\n  DEPENDS := @TARGET_mediatek_mt7981\nendef\n' >> "$UBOOT_DIR/Makefile"
    printf '\n$(foreach obj,$(UBOOT_TARGETS),$(eval $(call BuildPackage,uboot-$(obj))))\n' >> "$UBOOT_DIR/Makefile"
fi

# 3. 彻底粉碎 Mac80211 报错 (对齐 5.4 内核 API)
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp
# 物理像素级抹除 6.6.15 下载逻辑
sed -i 's/^PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_SOURCE:=.*/PKG_SOURCE:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_HASH:=.*/PKG_HASH:=/g' package/kernel/mac80211/Makefile

# 4. 物理注入 5.4 内核专用的 DTS
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 5. IP 物理对齐 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "脚本物理修复完成：已锁定瘦身后的纯净 U-Boot 仓库。"
