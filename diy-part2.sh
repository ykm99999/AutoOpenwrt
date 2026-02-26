#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =========================================================
# 核心指令：物理修复 SL-3000 U-Boot 构建死锁
# =========================================================

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    # 检查是否已存在定义，避免重复物理注入
    if ! grep -q "U-Boot/mt7981_sl_3000-nand" "$UBOOT_MAKEFILE"; then
        echo "执行 Pre-generation Audit：正在物理注入 SL-3000 U-Boot 定义..."
        
        # 使用 sed 在指定位置插入设备定义块（保持 Makefile 像素级结构对齐）
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

        # 物理修正 UBOOT_TARGETS 列表，确保编译器识别目标
        sed -i '/UBOOT_TARGETS += \\/a \	mt7981_sl_3000-nand \\\n	mt7981_sl_3000-emmc \\' "$UBOOT_MAKEFILE"
    fi
fi

# =========================================================
# 核心指令：常规物理修复（原文照抄，严禁画蛇添足）
# =========================================================

# 1. 修改默认 IP 地址（物理修复网络冲突）
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 修改默认主机名（物理对齐设备型号）
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 3. 移除不必要的默认软件包或进行物理替换（如有需要请在此处添加，严禁增加未授权功能）

echo "diy-part2.sh 执行完毕，SL-3000 物理环境修复完成。"
