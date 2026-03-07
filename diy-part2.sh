#!/bin/bash
set -e

echo "执行 diy-part2.sh：自定义配置修复"

# 1. 移除官方干扰补丁
rm -rf package/boot/uboot-mediatek/patches/* 2>/dev/null || true

# 2. 修改默认 IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 强制激活 U-Boot 包和目标设备配置
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
sed -i '/CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc/d' .config
echo "CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y" >> .config

# 4. 启用 ATF 依赖包
sed -i '/CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3/d' .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y" >> .config

# 5. 规范化配置
make defconfig

# 6. 注入自愈脚本
mkdir -p files/usr/bin
cat > files/usr/bin/self_healing.sh << 'EOF'
#!/bin/sh
# 简单网络自愈
if ! ping -c 1 -W 5 223.5.5.5 > /dev/null 2>&1; then
    /etc/init.d/network restart
fi
EOF
chmod +x files/usr/bin/self_healing.sh

echo "diy-part2.sh 执行完毕"
