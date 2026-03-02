#!/bin/bash
# 核心原则：原文照抄，只改错误，不画蛇添足，不偷工减料
# 物理审计：1.修改IP 2.注册DTS 3.净化源头 4.劫持U-Boot 5.激活救砖包开关

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (锁定内核 5.4 路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    # 物理防止重复注册，确保幂等性
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    # 物理追加：确保名称与 filogic.mk 中的 DEVICE_DTS 100% 匹配
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理源头净化 (核心修复：彻底解决 slot0 not found 等 MT7622 平台报错)
# 审计结论：物理删除除 filogic.mk 外的所有镜像定义，断绝非目标机型的干扰
find target/linux/mediatek/image/ -type f ! -name 'filogic.mk' ! -name 'Makefile' -delete

# 4. U-Boot 物理劫持 (物理锁定 1024M 引导链)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 5. 强制物理激活救砖包开关 (物理修复：解决 config 缺失导致的 fip.bin 不生成问题)
# 审计结论：必须强制写入 .config，否则构建系统不会触发 uboot-mediatek 编译
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
