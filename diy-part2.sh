#!/bin/bash

# 1. 物理移除官方补丁 (确保自定义源码纯净，防止 Patch 冲突)
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 物理修正默认 IP 为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 物理注册母版 1024M 内核 DTS (锁定物理位置)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 确保没有重复注册，精准插入 SL-3000 定义
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 4. 强制激活编译目标配置 (物理对齐 .config)
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config

# 5. 注入母版自愈脚本
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
if ! ping -c 1 -W 5 223.5.5.5 > /dev/null; then
    /etc/init.d/network restart
fi
EOF
chmod +x files/usr/bin/self_healing.sh
