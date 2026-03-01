#!/bin/bash
# 核心原则：延续上一版，原文照抄，只改错误
# 物理审计：在上一版指定的 diy-part2.sh 中注入物理修复，不画蛇添足

# 1. 物理修改 IP 地址 (延续上一版)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理修复 uboot-mediatek/Makefile (彻底解决 947 报错)
UBOOT_PATH="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_PATH" ]; then
    # 物理锁定变量：延续上一版修复逻辑，精准修改 URL 和版本
    sed -i "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_PATH"
    sed -i "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_PATH"
    
    # 物理单机型锁定：延续上一版逻辑，物理剔除其他机型，锁定 sl3000
    sed -i "s|^UBOOT_TARGETS := .*|UBOOT_TARGETS := mt7981_sl3000_emmc|g" "$UBOOT_PATH"
    # 物理扫描并清除残留追加行，确保物理排他性
    sed -i '/^UBOOT_TARGETS +=/d' "$UBOOT_PATH"
fi

# 3. 彻底删除其他设备：物理重写 mt7981.mk
MK_FILE="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MK_FILE" ]; then
    # 物理保留文件头，物理抹除后续所有 Device 定义
    sed -i '3,$d' "$MK_FILE"
    # 物理注入 SL3000 唯一机型定义
    echo "define Device/sl_3000-emmc" >> "$MK_FILE"
    echo "  DEVICE_VENDOR := SL" >> "$MK_FILE"
    echo "  DEVICE_MODEL := 3000 eMMC" >> "$MK_FILE"
    echo "  DEVICE_DTS := mt7981-sl-3000-emmc" >> "$MK_FILE"
    echo "  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek" >> "$MK_FILE"
    echo "  SUPPORTED_DEVICES := sl,3000-emmc" >> "$MK_FILE"
    echo "  DEVICE_PACKAGES := kmod-mmc kmod-fs-f2fs f2fsck mkf2fs" >> "$MK_FILE"
    echo "  IMAGES := sysupgrade.bin fip.bin" >> "$MK_FILE"
    echo "  IMAGE/fip.bin := append-u-boot | pad-to 1M" >> "$MK_FILE"
    echo "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata" >> "$MK_FILE"
    echo "endef" >> "$MK_FILE"
    echo "TARGET_DEVICES += sl_3000-emmc" >> "$MK_FILE"
fi

# 4. 物理注册 DTS (对应 24.10 内核物理路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi
