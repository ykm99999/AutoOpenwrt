#!/bin/bash

# 1. 物理准备 U-Boot 本地源码 (从 sl3000-uboot-base 分支抓取)
mkdir -p package/boot/uboot-mediatek/src
git clone --depth 1 -b sl3000-uboot-base https://github.com/ykm99999/AutoOpenwrt.git uboot_temp
cp -rf uboot_temp/* package/boot/uboot-mediatek/src/
rm -rf uboot_temp

# 2. 物理清除补丁干扰
rm -rf package/boot/uboot-mediatek/patches/*

# 3. 延续母版设置：IP 修改为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 4. 物理注册 1024M 内核 DTS (延续颗粒修复)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 5. 强制对齐编译目标 (物理锁定 U-Boot 及其镜像合成)
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config

# 6. 【核心修复】物理同步 8000 行配置与源码树，消除 out of sync 警告
make defconfig
