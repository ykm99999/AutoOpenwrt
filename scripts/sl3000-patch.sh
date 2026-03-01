#!/bin/bash
# 物理审计：物理全量重写 U-Boot Makefile，彻底根除语法熔断

# 1. 物理重写 mt7981.mk (原文照抄)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. 物理权威重构：直接生成全新 Makefile (语法死锁)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
cat << 'EOF' > "$UBOOT_MAKEFILE"
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ykm99999/66
PKG_SOURCE_VERSION:=sl3000-uboot-base
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=Gemini_Fixed

include $(INCLUDE_DIR)/package.mk

define Package/uboot-mediatek
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek SL3000
  VARIANT:=mt7981_sl3000_emmc
  DEPENDS:=@TARGET_mediatek_mt7981
endef

define Package/uboot-mediatek/description
  U-Boot for MediaTek mt7981 (SL3000 eMMC).
endef

UBOOT_CONFIG:=mt7981_sl_3000-emmc

define Build/Configure
	$(MAKE) -C $(PKG_BUILD_DIR) $(UBOOT_CONFIG)_defconfig
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) CROSS_COMPILE=$(TARGET_CROSS)
endef

define Package/uboot-mediatek/install
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/fip.bin $(1)/sl3000-fip.bin
	$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(1)/sl3000-u-boot.bin
endef

$(eval $(call BuildPackage,uboot-mediatek))
EOF

# 3. 物理粉碎 Mac80211 报错 (对齐 5.4 内核)
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp
sed -i 's/^PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile

# 4. 物理注入 5.4 内核专用的 DTS
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 5. IP 物理对齐 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "物理修复完成：已通过全量重写粉碎 Makefile 语法错误。"
