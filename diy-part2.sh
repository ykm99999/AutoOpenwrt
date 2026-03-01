#!/bin/bash
# 核心原则：延续上一版，原文照抄，只改错误，不画蛇添足
# 物理审计：移除已在仓库源修改好的 uboot 和 mk 文件修改逻辑，保持环境纯净

# 1. 物理修改 IP 地址 (延续上一版逻辑)
# 确保默认管理地址符合您的成功案例习惯
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (对应 24.10 内核物理路径)
# 即使源文件已改，此步骤用于物理确保内核 Makefile 包含您的 dtb 编译目标
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 物理防止重复注册
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    # 在指定位置物理追加注册行
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi
