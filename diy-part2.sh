#!/bin/bash

# 1. 物理移除官方干扰补丁 (确保自定义源码纯净编译)
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 基础网络配置：修改默认 IP 为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 物理注册内核 DTS (锁定 1024M 定义)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 先删除旧引用，再重新精准插入
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 4. 强制激活 U-Boot 构建配置 (确保 make package/... 能识别)
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config

# 5. 注入硬件自愈逻辑与看门狗
sed -i '/config system/a \	option watchdog "1"' package/base-files/files/etc/config/system
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
# 物理自愈：Ping 失败则重启网络
if ! ping -c 1 -W 5 223.5.5.5 > /dev/null; then
    sleep 30
    if ! ping -c 1 -W 5 114.114.114.114 > /dev/null; then
        /etc/init.d/network restart
    fi
fi
EOF
chmod +x files/usr/bin/self_healing.sh
mkdir -p files/etc/crontabs
echo "*/5 * * * * /usr/bin/self_healing.sh" >> files/etc/crontabs/root
