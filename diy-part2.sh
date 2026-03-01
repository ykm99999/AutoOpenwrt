#!/bin/bash
# 核心原则：原文照抄逻辑，物理锁死单一设备，修复语法错误

# 1. 修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 【彻底解决 947 报错】：精准修改 U-Boot 包装脚本
# 使用 ^ 符号严格锁定行首，不修改任何 define/endef 块内部结构，保证 Makefile 语法完整
UBOOT_PATH="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_PATH" ]; then
    # 物理锁定仓库地址和版本
    sed -i "s|^PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_PATH"
    sed -i "s|^PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_PATH"
    # 物理锁定唯一编译目标：mt7981_sl3000_emmc
    sed -i "s|^UBOOT_TARGETS := .*|UBOOT_TARGETS := mt7981_sl3000_emmc|g" "$UBOOT_PATH"
fi

# 3. 【删除其他所有设备】：物理重构 mt7981.mk
# 直接用 EOF 覆盖原文件，这样除了 SL3000 外，其他所有设备在编译阶段会全部消失
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

# 4. 物理注册 DTS
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    if ! grep -q "mt7981-sl-3000-emmc.dtb" "$DTS_MAKEFILE"; then
        sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
    fi
fi
