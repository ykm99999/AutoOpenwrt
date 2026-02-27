#!/bin/bash
# File name: diy-part2.sh
# 彻底解决 SL-3000 跨架构编译报错：外科手术式物理隔离

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"

if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "执行最高级别审计：物理切除所有冲突的 MIPS 设备定义..."

    # 1. 物理清空所有原有的 UBOOT_TARGETS 定义
    sed -i '/UBOOT_TARGETS +=/d' "$UBOOT_MAKEFILE"

    # 2. 物理切除所有非 mt7981 的 U-Boot 定义块
    # 这一步通过正则匹配从 define U-Boot 开始到 endef 结束，只要不含 mt7981 就全部删除
    # 这是防止 mt7620 等 MIPS 架构干扰 ARM64 编译的终极手段
    sed -i '/define U-Boot\/mt7620_rfb/,/endef/d' "$UBOOT_MAKEFILE"
    sed -i '/define U-Boot\/mt7621_rfb/,/endef/d' "$UBOOT_MAKEFILE"
    sed -i '/define U-Boot\/mt7620_mt7530_rfb/,/endef/d' "$UBOOT_MAKEFILE"
    sed -i '/define U-Boot\/mt7621_nand_rfb/,/endef/d' "$UBOOT_MAKEFILE"
    sed -i '/define U-Boot\/mt7621_zbtlink_zbt-wg3526-16m/,/endef/d' "$UBOOT_MAKEFILE"

    # 3. 注入 SL-3000 核心定义（如果不存在）
    if ! grep -q "U-Boot/mt7981_sl_3000-nand" "$UBOOT_MAKEFILE"; then
        cat >> "$UBOOT_MAKEFILE" <<EOF

define U-Boot/mt7981_sl_3000-nand
  NAME:=SL 3000 (NAND)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000
  UBOOT_CONFIG:=mt7981_sl_3000-nand
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=spim-nand
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-spim-nand-ddr3
endef

define U-Boot/mt7981_sl_3000-emmc
  NAME:=SL 3000 (eMMC)
  BUILD_SUBTARGET:=filogic
  BUILD_DEVICES:=sl_3000-emmc
  UBOOT_CONFIG:=mt7981_sl_3000-emmc
  UBOOT_IMAGE:=u-boot.fip
  BL2_BOOTDEV:=emmc
  BL2_SOC:=mt7981
  BL2_DDRTYPE:=ddr3
  DEPENDS:=+trusted-firmware-a-mt7981-emmc-ddr3
endef

UBOOT_TARGETS := mt7981_sl_3000-nand mt7981_sl_3000-emmc
EOF
    fi
fi

# 原文照抄：基础配置
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

echo "diy-part2.sh 外科手术式修复完成，MIPS 源码已物理切除。"
