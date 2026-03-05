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
UBOOT_MAKE_FLAGS += NO_YAML=1

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -fpR $(CURDIR)/src/. $(PKG_BUILD_DIR)/
endef

define Package/U-Boot
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek MT7981 (SL 3000 eMMC)
  DEPENDS:=@TARGET_mediatek_mt7981
endef

define U-Boot/Default
  BUILD_TARGET:=mediatek
  UBOOT_IMAGE:=u-boot-mtk.bin
  HIDDEN:=1
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=mt7981
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_emmc
  UBOOT_IMAGE:=u-boot.fip
endef

UBOOT_TARGETS := mt7981_sl_3000-emmc

define Build/fip-image
	BL2_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin" ; \
	BL31_BIN="$(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl31.bin" ; \
	$(STAGING_DIR_HOST)/bin/fiptool create \
		--tb-fw $$BL2_BIN \
		--soc-fw $$BL31_BIN \
		--nt-fw $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.bin \
		$(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip
endef

define Build/Compile
	$(call Build/Compile/U-Boot)
	$(call Build/fip-image)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 物理修复：重命名救砖件以匹配 Device 定义，防止镜像合成失败
	$(CP) $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin $(STAGING_DIR_IMAGE)/emmc-preloader.bin
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip $(STAGING_DIR_IMAGE)/emmc-bl31-uboot.fip
	$(CP) $(PKG_BUILD_DIR)/$(BUILD_VARIANT)/u-boot.fip $(STAGING_DIR_IMAGE)/u-boot.fip
endef

$(eval $(call BuildPackage,U-Boot))
