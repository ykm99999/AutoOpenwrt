#!/bin/bash
# 1. 物理修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (确保内核 Makefile 能识别你仓库里的文件)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理锁定 U-Boot 救砖源 (ykm99999/66)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    sed -i "s/UBOOT_TARGETS := .*/UBOOT_TARGETS := mt7981_sl3000_emmc/g" "$UBOOT_MAKEFILE"
fi
