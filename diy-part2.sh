#!/bin/bash
# 核心原则：延续上一版，原文照抄，只改错误，不画蛇添足
# 物理审计：源文件已修复 TITLE，脚本物理熔断对 uboot Makefile 的所有修改

# 1. 物理修改 IP 地址 (延续上一版逻辑)
# 确保默认管理地址为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (对应 24.10 内核物理路径)
# 物理确保内核编译链包含您的 sl-3000-emmc 目标
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 物理防止重复注册：先删再加，确保唯一性
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    # 在指定机型后物理追加注册行
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 物理审计备注：已物理移除针对 uboot-mediatek/Makefile 的所有 sed 操作，
# 确保编译系统直接读取您仓库中已修复好的物理源文件。
