#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
#

# =========================================================
# 核心修复：物理屏蔽非 SL-3000 设备，防止架构冲突报错
# =========================================================

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理清除 UBOOT_TARGETS 原有定义，防止 MIPS 设备触发 ARM64 编译错误
    # 仅保留 SL-3000 及其物理依赖
    echo "正在执行物理修复：清理架构冲突目标并注入 SL-3000 定义..."
    
    # 1. 物理移除 Makefile 中原有的 UBOOT_TARGETS 累加逻辑（防止旧设备被编译）
    sed -i '/UBOOT_TARGETS +=/d' "$UBOOT_MAKEFILE"

    # 2. 注入 SL-3000 U-Boot 定义（如果不存在）
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

    # 3. 物理锁定编译目标：仅允许编译 SL-3000，解决架构死锁
    echo -e "\nUBOOT_TARGETS += mt7981_sl_3000-nand mt7981_sl_3000-emmc" >> "$UBOOT_MAKEFILE"
fi

# =========================================================
# 原文照抄：其他补丁逻辑
# =========================================================
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

echo "diy-part2.sh 物理修复完成。"
