#!/bin/bash
# 1. 物理修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册：由于源码中已包含 DTS，只需确保 Makefile 存在编译指令
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    if ! grep -q "mt7981-sl-3000-emmc.dtb" "$DTS_MAKEFILE"; then
        sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
    fi
fi

# 3. 物理锁定 U-Boot 救砖源 (ykm99999/66)
# 这一步必须保留，因为 FIP 构建依赖于特定的 U-Boot 仓库
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    sed -i "s/UBOOT_TARGETS := .*/UBOOT_TARGETS := mt7981_sl3000_emmc/g" "$UBOOT_MAKEFILE"
fi
