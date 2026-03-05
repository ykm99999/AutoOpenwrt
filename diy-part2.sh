#!/bin/bash

# 1. 物理准备 U-Boot 本地源码 (同一仓库的分支抓取)
# 这一步是让 Makefile 的 cp -fpR $(CURDIR)/src 生效的关键
mkdir -p package/boot/uboot-mediatek/src
git clone --depth 1 -b sl3000-uboot-base https://github.com/ykm99999/54.git uboot_temp
cp -rf uboot_temp/* package/boot/uboot-mediatek/src/
rm -rf uboot_temp

# 2. 默认 IP 修改
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 注册 1024M 内核 DTS
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 4. 强制启用 U-Boot 包
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
