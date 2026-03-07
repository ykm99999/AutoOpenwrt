#
# SPDX-License-Identifier: GPL-2.0-only
# 使用本地 src 源码的最终版本
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_VERSION:=custom
PKG_RELEASE:=1
PKG_SOURCE:=
PKG_SOURCE_URL:=
PKG_HASH:=skip
PKG_MD5SUM:=
PKG_MAINTAINER:=Gemini_AI

PKG_PATCH_DIR:=

PKG_BUILD_DEPENDS:=!(TARGET_ramips||TARGET_mediatek_mt7623):arm-trusted-firmware-tools/host

UBOOT_USE_INTREE_DTC:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/host-build.mk

# 强制禁用 YAML 输出
UBOOT_MAKE_FLAGS += NO_YAML=1

# 自定义准备阶段：从本地 src 复制源码
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -fpR $(CURDIR)/src/. $(PKG_BUILD_DIR)/
endef

define Package/U-Boot
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek MT7981 (SL 3000 eMMC)
  DEPENDS:=@TARGET_mediatek_mt7981
  URL:=https://github.com/ykm99999/AutoOpenwrt/tree/sl3000-uboot-base
endef

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

UBOOT_CUSTOMIZE_CONFIG := \
	--disable TOOLS_KWBIMAGE \
	--disable TOOLS_LIBCRYPTO \
	--disable TOOLS_MKEFICAPSULE \
	--enable SERIAL_RX_BUFFER \
	--set-val SERIAL_RX_BUFFER_SIZE 256

ifdef CONFIG_TARGET_mediatek
UBOOT_MAKE_FLAGS += $(UBOOT_IMAGE:.fip=.bin)
endif

define Build/fip-image
	BL2_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin" ; \
	BL31_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin" ; \
	if [ ! -f "$$BL2_BIN" ]; then \
		echo "ERROR: BL2 not found at $$BL2_BIN"; exit 1; \
	fi ; \
	if [ ! -f "$$BL31_BIN" ]; then \
		echo "ERROR: BL31 not found at $$BL31_BIN"; exit 1; \
	fi ; \
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--tb-fw $$BL2_BIN \
		--soc-fw $$BL31_BIN \
		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip
endef

define Build/Configure
	$(call Build/Configure/U-Boot)
	sed -i '/^CONFIG_TOOLS_LIBCRYPTO=y/s/.*/# CONFIG_TOOLS_LIBCRYPTO is not set/' $(PKG_BUILD_DIR)/.config
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
ifeq ($(UBOOT_IMAGE),u-boot.fip)
	$(call Build/fip-image)
endif
endef

ifdef CONFIG_TARGET_mediatek
define Package/u-boot/install
endef
endif

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/share/u-boot
	$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip \
		$(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-bl2.bin $(STAGING_DIR_IMAGE)/
	$(CP) $(STAGING_DIR_HOST)/share/u-boot/mt7981-emmc-ddr3-fip.bin $(STAGING_DIR_IMAGE)/
endef

$(eval $(call BuildPackage,U-Boot))
