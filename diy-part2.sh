#!/bin/bash
# 核心原则：物理路径纠偏 + 补丁清空 + 1024M 锁定

# 1. 物理移除冲突补丁 (防止自定义仓库 patch 报错)
rm -rf package/boot/uboot-mediatek/patches/*

# 2. 物理纠正 U-Boot 产物分发逻辑 (终极修复路径报错)
# 强制修改 Makefile 里的 cp 动作，将产物重命名为镜像宏需要的固定名称
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    echo "正在物理对齐 U-Boot 产物分发路径..."
    sed -i 's/\$(CP) \$(PKG_BUILD_DIR)\/\$(1)\/bl2.bin \$(STAGING_DIR_IMAGE)\/.*/$(CP) $(PKG_BUILD_DIR)\/$(1)\/bl2.bin $(STAGING_DIR_IMAGE)\/mt7981-emmc-ddr3-bl2.bin/' "$UBOOT_MAKEFILE"
    sed -i 's/\$(CP) \$(PKG_BUILD_DIR)\/\$(1)\/u-boot.fip \$(STAGING_DIR_IMAGE)\/.*/$(CP) $(PKG_BUILD_DIR)\/$(1)\/u-boot.fip $(STAGING_DIR_IMAGE)\/mt7981-emmc-ddr3-u-boot.fip/' "$UBOOT_MAKEFILE"
fi

# 3. 基础配置：修改默认 IP (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 4. 物理注册 DTS (锁定 1024M 内存定义)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 5. 锁定编译目标并开启自愈
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
sed -i '/config system/a \	option watchdog "1"' package/base-files/files/etc/config/system

# 6. 注入自愈脚本：检测网络失败则重启
mkdir -p files/usr/bin
cat << 'EOF' > files/usr/bin/self_healing.sh
#!/bin/sh
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
