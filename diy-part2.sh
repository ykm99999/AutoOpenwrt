#!/bin/bash
# File name: diy-part2.sh
# 核心原则：原文照抄，只改错误，物理锁死 SL3000 eMMC

# 1. 物理修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理修复 U-Boot Makefile (精准修复 Error 13s)
UBOOT_PATH="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_PATH" ]; then
    # 物理锁定仓库 URL 与分支
    sed -i "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_PATH"
    sed -i "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_PATH"
    
    # 【删除其他设备的关键逻辑】：物理强制覆盖编译目标
    # 这样编译器只会寻找 mt7981_sl3000_emmc，其他几百个设备定义会被逻辑忽略
    sed -i "s|^UBOOT_TARGETS := .*|UBOOT_TARGETS := mt7981_sl3000_emmc|g" "$UBOOT_PATH"
fi

# 3. 物理重写 MK 文件 (删除其他设备，仅保留 SL-3000 eMMC)
# 这一步实现了您“删除其他设备”的要求，且不影响 Makefile 稳定性
MK_PATH="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MK_PATH" ]; then
cat << 'EOF' > "$MK_PATH"
KERNEL_LOADADDR := 0x48080000

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := kmod-mmc kmod-fs-f2fs f2fsck mkf2fs
  IMAGES := sysupgrade.bin fip.bin
  IMAGE/fip.bin := append-u-boot | pad-to 1M
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF
fi

# 4. 物理注册 DTS (确保内核识别)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    if ! grep -q "mt7981-sl-3000-emmc.dtb" "$DTS_MAKEFILE"; then
        sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
    fi
fi
