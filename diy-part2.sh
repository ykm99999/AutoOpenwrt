#!/bin/bash
set -e

echo "执行 diy-part2.sh：自定义配置修复"

# 1. 移除官方干扰补丁（如果存在）
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 修改默认 IP 为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 在 mt7981.mk 中注册 SL-3000 设备（如果尚未注册）
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    if ! grep -q "define Device/sl_3000-emmc" "$MT7981_MK"; then
        echo "在 $MT7981_MK 中添加 SL-3000 设备定义"
        echo >> "$MT7981_MK"
        echo "define Device/sl_3000-emmc" >> "$MT7981_MK"
        echo "  DEVICE_VENDOR := SL" >> "$MT7981_MK"
        echo "  DEVICE_MODEL := 3000 (eMMC)" >> "$MT7981_MK"
        echo "  DEVICE_DTS := mt7981-sl-3000-emmc" >> "$MT7981_MK"
        echo "  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek" >> "$MT7981_MK"
        echo "  SUPPORTED_DEVICES := sl,3000-emmc" >> "$MT7981_MK"
        echo "  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata" >> "$MT7981_MK"
        echo "endef" >> "$MT7981_MK"
        echo "TARGET_DEVICES += sl_3000-emmc" >> "$MT7981_MK"
    else
        echo "设备 sl_3000-emmc 已在 $MT7981_MK 中定义，跳过"
    fi
else
    echo "错误：$MT7981_MK 不存在，无法注册设备！" >&2
    exit 1
fi

# 4. 强制激活 U-Boot 包和目标设备配置
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
sed -i '/CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc/d' .config
echo "CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y" >> .config

# 5. 启用 ATF 依赖包（由 U-Boot Makefile 的 DEPENDS 指定）
sed -i '/CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3/d' .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-emmc-ddr3=y" >> .config

# 6. 规范化配置
make defconfig

# 7. 注入自愈脚本
mkdir -p files/usr/bin
> files/usr/bin/self_healing.sh
echo '#!/bin/sh' >> files/usr/bin/self_healing.sh
echo '# 简单网络自愈：若无法 ping 通外网则重启网络服务' >> files/usr/bin/self_healing.sh
echo 'if ! ping -c 1 -W 5 223.5.5.5 > /dev/null 2>&1; then' >> files/usr/bin/self_healing.sh
echo '    /etc/init.d/network restart' >> files/usr/bin/self_healing.sh
echo 'fi' >> files/usr/bin/self_healing.sh
chmod +x files/usr/bin/self_healing.sh

echo "diy-part2.sh 执行完毕"
