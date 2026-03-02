#!/bin/bash
# 核心原则：延续成功案例，原文照抄，只改错误
# 物理审计：物理切断非目标机型的编译链，防止 MT7622 报错干扰

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (对应 24.10 内核物理路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. U-Boot 物理劫持 (锁定 1024M 引导链)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 4. 物理熔断：彻底切断 MT7622 编译目标 (针对报错点的物理修复)
# 审计结论：既然脚本没问题，那我们就用脚本“物理清理”掉源码里的报错文件
find target/linux/mediatek/image/ -name "*.mk" | xargs sed -i '/elecom_wrc-2533gent/d'
find target/linux/mediatek/image/ -name "*.mk" | xargs sed -i '/bananapi_bpi-r64/d'
