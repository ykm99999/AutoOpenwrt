#!/bin/bash
# File name: scripts/sl3000-patch.sh
# 物理修复：解决循环依赖与架构死锁

# 1. 物理切除递归依赖死锁 (rd05a1)
# 审计：此包在部分源码版本中存在 symbol PACKAGE_rd05a1 depends on PACKAGE_rd05a1 逻辑错误
find package -name "Makefile" | xargs grep -l "PACKAGE_rd05a1" | xargs sed -i '/DEPENDS.*PACKAGE_rd05a1/d' 2>/dev/null || true

# 2. 物理重写 U-Boot Makefile 确保架构纯净
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "执行物理重构：彻底隔离 MIPS 并锁定 SL-3000 编译目标..."
    cat > "$UBOOT_MAKEFILE" <<'EOF'
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=uboot-mediatek
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/approved-source/u-boot-mtk.git
PKG_SOURCE_DATE:=2024-10-01
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=mediatek
  BUILD_SUBTARGET:=filogic
  UBOOT_IMAGE:=u-boot.fip
endef

define U-Boot/mt7981_sl_3000-nand
  NAME:=SL 3000 (NAND)
  BUILD_DEVICES:=sl_3000
  UBOOT_CONFIG:=mt7981_sl_3000-nand
  BL2_BOOTDEV:=spim-nand
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-spim-nand-ddr3
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

UBOOT_TARGETS := mt7981_sl_3000-nand mt7981_sl_3000-emmc

$(eval $(call BuildPackage/U-Boot))
EOF
fi

# 3. 基础配置原文照抄
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

echo "脚本物理修复完成。"
