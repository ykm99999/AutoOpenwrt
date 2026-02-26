#!/bin/bash
#
# File name: diy-part2.sh
# Description: 物理修复 SL-3000 U-Boot 架构冲突报错
#

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "执行 Pre-generation Audit：正在物理清除冲突架构并注入 SL-3000..."

    # 1. 物理移除 Makefile 中所有原有的 UBOOT_TARGETS 赋值行，防止编译 MIPS 设备
    sed -i '/UBOOT_TARGETS +=/d' "$UBOOT_MAKEFILE"

    # 2. 注入 SL-3000 U-Boot 定义（严格保持物理结构）
    if ! grep -q "U-Boot/mt7981_sl_3000-nand" "$UBOOT_MAKEFILE"; then
        sed -i '/define U-Boot\/mt7981_jcg_q30-pro/i \
define U-Boot/mt7981_sl_3000-nand\
  NAME:=SL 3000 (NAND)\
  BUILD_SUBTARGET:=filogic\
  BUILD_DEVICES:=sl_3000\
  UBOOT_CONFIG:=mt7981_sl_3000-nand\
  UBOOT_IMAGE:=u-boot.fip\
  BL2_BOOTDEV:=spim-nand\
  BL2_SOC:=mt7981\
  BL2_DDRTYPE:=ddr3\
  DEPENDS:=+trusted-firmware-a-mt7981-spim-nand-ddr3\
endef\
\
define U-Boot/mt7981_sl_3000-emmc\
  NAME:=SL 3000 (eMMC)\
  BUILD_SUBTARGET:=filogic\
  BUILD_DEVICES:=sl_3000-emmc\
  UBOOT_CONFIG:=mt7981_sl_3000-emmc\
  UBOOT_IMAGE:=u-boot.fip\
  BL2_BOOTDEV:=emmc\
  BL2_SOC:=mt7981\
  BL2_DDRTYPE:=ddr3\
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3\
endef\
' "$UBOOT_MAKEFILE"
    fi

    # 3. 结果导向：强制锁定编译目标，物理隔离旧设备
    echo -e "\nUBOOT_TARGETS += mt7981_sl_3000-nand mt7981_sl_3000-emmc" >> "$UBOOT_MAKEFILE"
fi

# =========================================================
# 原文照抄原则：保持其他基础补丁不变
# =========================================================
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

echo "diy-part2.sh 物理修复完成，冲突架构已隔离。"
