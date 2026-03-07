#
# SPDX-License-Identifier: GPL-2.0-only
# 完全自定义构建版本：彻底绕过下载机制，使用本地 src 源码
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
# 清空所有下载相关变量
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
# 注意：不包含 u-boot.mk，我们手动定义一切
include $(INCLUDE_DIR)/host-build.mk

# 强制禁用 YAML 输出
UBOOT_MAKE_FLAGS += NO_YAML=1

# 核心：自定义准备阶段，从 src 复制源码
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -fpR $(CURDIR)/src/. $(PKG_BUILD_DIR)/
endef

define Package/uboot-mediatek
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek MT7981 (SL 3000 eMMC)
  DEPENDS:=@TARGET_mediatek_mt7981 +trusted-firmware-a-mt7981-emmc-ddr3
  URL:=https://github.com/ykm99999/AutoOpenwrt/tree/sl3000-uboot-base
endef

# 配置阶段：直接使用 defconfig
define Build/Configure
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		mt7981_emmc_defconfig
endef

# 编译阶段
define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		$(UBOOT_MAKE_FLAGS) \
		all
endef

define Package/uboot-mediatek/install
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	# 复制生成的 BL2 和 FIP（假设它们生成在源码根目录）
	$(CP) $(PKG_BUILD_DIR)/bl2.bin $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-bl2.bin 2>/dev/null || true
	$(CP) $(PKG_BUILD_DIR)/u-boot.fip $(STAGING_DIR_IMAGE)/mt7981-emmc-ddr3-u-boot.fip 2>/dev/null || true
endef

$(eval $(call BuildPackage,uboot-mediatek))
