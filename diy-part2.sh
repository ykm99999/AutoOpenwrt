#!/bin/bash

# 1. 物理清理：抹除官方 U-Boot 干扰，删除所有 patch 防止 512M 逻辑干扰 1024M
rm -rf package/boot/uboot-mediatek/src
rm -rf package/boot/uboot-mediatek/patches/*
mkdir -p package/boot/uboot-mediatek/src

# 2. 物理注入：拉取 sl3000-uboot-base 分支的 1024M 物理源码
git clone --depth 1 -b sl3000-uboot-base https://github.com/ykm99999/AutoOpenwrt.git uboot_temp
cp -rf uboot_temp/* package/boot/uboot-mediatek/src/
rm -rf uboot_temp

# 3. 物理修复 Makefile：彻底抹除 PKG_SOURCE 规避 404，对接 Artifact
cat <<'EOF' > package/boot/uboot-mediatek/Makefile
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=custom
PKG_RELEASE:=1

PKG_SOURCE:=
PKG_SOURCE_URL:=
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/host-build.mk

UBOOT_USE_INTREE_DTC:=1

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Package/U-Boot
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for SL 3000 (1024M DDR)
  DEPENDS:=@TARGET_mediatek_mt7981
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=mt7981
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--tb-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin \
		--soc-fw $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin \
		--nt-fw $(PKG_BUILD_DIR)/u-boot.bin \
		$(PKG_BUILD_DIR)/u-boot.fip
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(PKG_BUILD_DIR)/u-boot.fip $(STAGING_DIR_IMAGE)/emmc-bl31-uboot.fip
endef

$(eval $(call BuildPackage,U-Boot))
EOF

# 4. 物理注入 Device 定义 (严格延续上一版原文)
DEVICE_FILE="target/linux/mediatek/image/mt7981.mk"
sed -i '/define Device\/sl_3000-emmc/,/endef/d' "$DEVICE_FILE"
cat <<'EOF' >> "$DEVICE_FILE"

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
  IMAGE/factory.img.gz := mt798x-gpt emmc |\
	pad-to 17k | mt7981-bl2 emmc-ddr3 |\
	pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 |\
	pad-to 64M | append-image squashfs-sysupgrade.itb | gzip
endef
TARGET_DEVICES += sl_3000-emmc
EOF

# 5. 【彻底解决架构冲突】物理锁定：先清除所有目标，再强制锁定 MT7981
sed -i 's/CONFIG_TARGET_.*=y/# & is not set/g' .config
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981=y" >> .config
echo "CONFIG_TARGET_mediatek_mt7981_DEVICE_sl_3000-emmc=y" >> .config
