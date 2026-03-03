#!/bin/bash
# 核心原则：源头已手动物理修复，脚本仅做环境注入，绝不重复修改或覆盖 Makefile/MK 文件

# 1. 物理修改默认 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (确保内核构建包含 1024M 的 mt7981-sl-3000-emmc.dtb)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 先清理旧行，再精准插入，确保您的自定义 DTS 参与内核编译链条
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理激活 U-Boot 编译开关与包依赖
# 审计：确保 .config 开启 U-Boot 包并与镜像目标对齐，彻底规避 cat 找不到文件报错
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek=y" >> .config
