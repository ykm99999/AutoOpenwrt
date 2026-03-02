#!/bin/bash
# 核心原则：既然 Makefile/MK/DTS 源头已修复，脚本仅做环境注入，绝不重复修改 mk 文件

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (确保内核 Makefile 包含您的 emmc.dtb)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 先清理旧行，再精准插入，确保 1024M DTS 参与编译
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. U-Boot 物理劫持 (1024M 引导链闭环)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理清理旧的劫持指令
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    # 物理注入 1024M 配置文件下载指令，确保 Preloader 和 FIP 识别 1GB RAM
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 4. 强制物理激活 U-Boot 编译开关
# 审计：确保无论 .config 如何，都会物理产出最新的 FIP 救砖包
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
