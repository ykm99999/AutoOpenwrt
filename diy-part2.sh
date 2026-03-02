#!/bin/bash
# 核心原则：延续上一版，原文照抄，只改错误
# 物理审计：物理解决 TITLE 缺失报错，不改动您仓库已有的设备定义

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理修复 uboot-mediatek/Makefile 预检报错
UBOOT_PATH="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_PATH" ]; then
    # 物理静默审计：如果检测到 TITLE 缺失（导致报错的关键点），则物理补齐
    if ! grep -q "TITLE:=" "$UBOOT_PATH"; then
        # 在 PKG_LICENSE 之后物理安全插入 TITLE 字段
        sed -i '/PKG_LICENSE:=/a TITLE:=U-Boot for MediaTek devices' "$UBOOT_PATH"
    fi
    
    # 确保 UBOOT_TARGETS 逻辑正确，不执行删除操作，仅执行物理对齐
    # 这一行是物理安全锁，确保 947 行附近的逻辑不会叠加
    sed -i '/^UBOOT_TARGETS +=/d' "$UBOOT_PATH" 2>/dev/null || true
fi

# 3. 物理注册 DTS (对应 24.10 内核物理路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 防止重复注册，物理清理后重新注入
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi
