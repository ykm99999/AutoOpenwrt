#!/bin/bash
# 核心原则：源头已物理修复，脚本仅做环境注入，绝不干预 Makefile/MK 逻辑

# 1. 物理修改默认 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (确保内核构建包含 1024M 的 mt7981-sl-3000-emmc.dtb)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 先清理旧行，再精准插入，确保您的自定义 DTS 参与内核编译链条
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理激活 U-Boot 编译开关
# 审计：此开关物理对齐您在 uboot-mediatek/Makefile 中定义的 UBOOT_TARGETS 名称
# 确保在编译时，.config 文件中该目标为 'y'，否则 ARTIFACTS 提取宏会因为找不到文件而报错
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
