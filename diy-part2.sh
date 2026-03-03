#!/bin/bash
# 核心原则：物理路径纠偏 + 补丁清空 + 自愈注入

# 1. 物理清空 U-Boot 补丁（防止自定义 66.git 仓库执行 patch 报错）
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 基础配置：修改默认 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 物理注册 DTS (锁定 1024M 内存定义)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 4. 物理激活 U-Boot 编译开关
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config

# 5. 【自愈系统】硬件看门狗 + 网络守护
sed -i '/config system/a \	option watchdog "1"' package/base-files/files/etc/config/system

mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
CHECK_IP="223.5.5.5"
if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
    sleep 30
    if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
        /etc/init.d/network restart
        sleep 300
        if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
            reboot
        fi
    fi
fi
EOF
chmod +x files/usr/bin/self_healing.sh

mkdir -p files/etc/crontabs
echo "*/5 * * * * /usr/bin/self_healing.sh" >> files/etc/crontabs/root
