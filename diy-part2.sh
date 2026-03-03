#!/bin/bash
# 核心原则：源头已物理修复，脚本仅做环境注入，绝不重复修改或覆盖 Makefile/MK 文件

# 1. 物理修改默认 IP 地址 (192.168.1.2)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (确保内核编译包含您的 1024M mt7981-sl-3000-emmc.dtb)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 清理旧行并精准插入，确保 DTS 物理参与构建
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 强制激活 U-Boot 编译开关
# 审计：此开关物理对齐您在 uboot-mediatek/Makefile 中定义的 UBOOT_TARGETS
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
