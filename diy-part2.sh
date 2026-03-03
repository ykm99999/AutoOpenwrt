#!/bin/bash
set -e  # 遇到错误立即退出

echo "执行 diy-part2.sh：自定义配置修复"

# 1. 移除官方干扰补丁
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 修改默认 IP 为 192.168.1.2
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 3. 修复 uboot-mediatek Makefile 缺失的 TITLE 字段
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 检查 Package 定义块是否存在
    if ! grep -q "define Package/uboot-mediatek" "$UBOOT_MAKEFILE"; then
        echo "警告：未找到 Package/uboot-mediatek 定义块，正在添加完整定义..."
        # 在文件末尾添加定义块（包含 TITLE 和其他必需字段）
        cat << 'EOF' >> "$UBOOT_MAKEFILE"

define Package/uboot-mediatek
  SECTION:=boot
  CATEGORY:=Boot Loaders
  TITLE:=U-Boot for MediaTek MT7981 (SL 3000 eMMC)
  DEPENDS:=@TARGET_mediatek_mt7981
  URL:=https://github.com/ykm99999/66.git
endef
EOF
    else
        # 定义块存在，检查是否已有 TITLE
        if ! grep -q "TITLE:=" "$UBOOT_MAKEFILE"; then
            echo "添加 TITLE 字段到 $UBOOT_MAKEFILE"
            # 在 define Package/uboot-mediatek 行后插入 TITLE（注意缩进为两个空格）
            sed -i '/define Package\/uboot-mediatek/a \ \ TITLE:=U-Boot for MediaTek MT7981 (SL 3000 eMMC)' "$UBOOT_MAKEFILE"
        fi
    fi
else
    echo "错误：$UBOOT_MAKEFILE 不存在！" >&2
    exit 1
fi

# 4. 注册设备树文件到 DTS Makefile
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    echo "更新 DTS Makefile：添加 mt7981-sl-3000-emmc.dtb"
    # 先删除可能存在的旧条目，避免重复
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    # 在 dtb 列表末尾追加（假设列表以 dtb-$(CONFIG_ARCH_MEDIATEK) += 开头）
    sed -i '/dtb-$(CONFIG_ARCH_MEDIATEK) +=/ s/$/ mt7981-sl-3000-emmc.dtb/' "$DTS_MAKEFILE"
else
    echo "警告：$DTS_MAKEFILE 不存在，跳过 DTS 注册" >&2
fi

# 5. 强制激活编译目标配置
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' .config
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config

# 6. 规范化配置（生成完整 .config）
make defconfig

# 7. 注入自愈脚本
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
# 简单网络自愈：若无法 ping 通外网则重启网络服务
if ! ping -c 1 -W 5 223.5.5.5 > /dev/null 2>&1; then
    /etc/init.d/network restart
fi
EOF
chmod +x files/usr/bin/self_healing.sh

echo "diy-part2.sh 执行完毕"
