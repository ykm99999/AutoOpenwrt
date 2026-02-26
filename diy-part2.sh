#!/bin/bash
#
# File name: diy-part2.sh
# Description: 彻底解决 SL-3000 U-Boot 架构冲突物理修复
#

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "执行顶级审计修复：物理隔离非 ARM64 目标..."

    # 1. 核心修复：物理删除 Makefile 中所有已存在的 UBOOT_TARGETS 累加行
    # 这将彻底屏蔽导致报错的 mt7620, mt7621 等 MIPS 设备
    sed -i '/UBOOT_TARGETS +=/d' "$UBOOT_MAKEFILE"

    # 2. 原文照抄注入 SL-3000 定义（确保设备信息完整）
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

    # 3. 结构死锁：重新物理声明 UBOOT_TARGETS，仅包含 SL-3000
    # 确保执行环境只尝试编译 ARM64 兼容目标
    echo -e "\nUBOOT_TARGETS := mt7981_sl_3000-nand mt7981_sl_3000-emmc" >> "$UBOOT_MAKEFILE"
fi

# =========================================================
# 原文照抄：基础配置修复
# =========================================================
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

echo "diy-part2.sh 物理加固完成，报错目标已彻底剔除。"
