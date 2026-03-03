#!/bin/bash
# 核心原则：源头已物理修复，脚本负责环境注入与自愈逻辑设置

# 1. 基础配置：修改 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (锁定 1024M 内存定义)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理激活 U-Boot 编译开关与包依赖
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config

# 4. 【自愈逻辑】物理集成：硬件看门狗 + 网络守护
# 激活系统看门狗（防止内核死锁）
sed -i '/config system/a \	option watchdog "1"' package/base-files/files/etc/config/system

# 注入物理自愈脚本：检测网络，失败则尝试重启网络或系统
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
# 物理审计：如果连续 3 次 Ping 失败，重启网络；如果 10 分钟后依然失败，强制重启系统
CHECK_IP="223.5.5.5"
if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
    sleep 30
    if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
        logger -t "Self-Healing" "Network down, restarting network..."
        /etc/init.d/network restart
        sleep 300
        if ! ping -c 1 -W 5 $CHECK_IP > /dev/null; then
            logger -t "Self-Healing" "Critical failure, rebooting..."
            reboot
        fi
    fi
fi
EOF
chmod +x files/usr/bin/self_healing.sh

# 加入 Crontab 每 5 分钟执行一次
mkdir -p files/etc/crontabs
echo "*/5 * * * * /usr/bin/self_healing.sh" >> files/etc/crontabs/root
