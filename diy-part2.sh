#!/bin/bash
# 核心原则：物理隔离非 MT7981 逻辑，确保 1024M 编译链路纯净

# 1. 物理清理：只保留 mt7981 相关补丁，彻底删除 mt7622/mt7623/mt7986 等无关干扰项
# 审计：由于使用自定义源码仓库，官方通用补丁极易导致 Patch 阶段熔断
PATCH_DIR="package/boot/uboot-mediatek/patches"
if [ -d "$PATCH_DIR" ]; then
    echo "正在物理清理无关芯片补丁..."
    find "$PATCH_DIR" -type f ! -name "*mt7981*" -delete
fi

# 2. 基础配置：修改默认 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 物理注册 DTS (锁定 1024M 内存物理定义)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 确保自定义 DTS 参与内核编译链条
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 4. 物理锁定编译目标：强制选中并激活 uboot-mediatek
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config

# 5. 【自愈逻辑】注入：硬件看门狗 + 网络守护
# 激活系统硬件看门狗
sed -i '/config system/a \	option watchdog "1"' package/base-files/files/etc/config/system

# 注入自愈脚本：检测网络连通性
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
# 连续两次 Ping 失败则尝试重启网络，最终失败则重启系统
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

# 加入定时任务 (每 5 分钟执行一次)
mkdir -p files/etc/crontabs
echo "*/5 * * * * /usr/bin/self_healing.sh" >> files/etc/crontabs/root
