#!/bin/bash
# 核心原则：延续上一版成功案例，原文照抄，只改错误，绝对不准偷工减料
# 物理审计：物理注入 U-Boot 劫持逻辑，锁定 1024M 引导链

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (对应 24.10 内核物理路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. U-Boot 物理劫持 (锁定 1024M 引导链)
# 审计结论：必须物理覆盖 Makefile 中的配置，确保救砖包内存定义正确
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理清理旧残留，防止重复注入
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    # 在 Build/Configure 之后物理劫持远程 defconfig
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi
