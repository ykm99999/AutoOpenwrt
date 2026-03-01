#!/bin/bash
# 核心原则：原文照抄，只改错误，严禁画蛇添足
# 物理检查：不使用 EOF，通过 sed 精准重构物理文件

# 1. 物理修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理修复 package/boot/uboot-mediatek/Makefile (解决 947 报错)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理锁定变量区：精准修改 URL 和版本，防止破坏后续宏块
    sed -i "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    
    # 物理删除其他所有设备定义：通过精准替换 UBOOT_TARGETS 实现“物理删除”
    # 我们直接把原本所有的 UBOOT_TARGETS 行替换为单机型定义
    sed -i "s|^UBOOT_TARGETS := .*|UBOOT_TARGETS := mt7981_sl3000_emmc|g" "$UBOOT_MAKEFILE"
    
    # 物理安全审计：删除可能存在的多余 UBOOT_TARGETS 追加行
    sed -i '/^UBOOT_TARGETS +=/d' "$UBOOT_MAKEFILE"
fi

# 3. 物理重构 target/linux/mediatek/image/mt7981.mk (实现删除其他设备)
# 注意：为了不使用 EOF，我们使用 sed 的 'd' 指令物理清除除头部外的所有内容，再重新追加
MK_FILE="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MK_FILE" ]; then
    # 物理保留前两行 (通常是 KERNEL_LOADADDR)，删除后续所有行
    sed -i '3,$d' "$MK_FILE"
    # 物理追加 SL3000 eMMC 专用定义
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

# 4. 物理注册 DTS (对应 24.10 内核路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 先物理移除旧的注册行（防止重复），再重新追加
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi
