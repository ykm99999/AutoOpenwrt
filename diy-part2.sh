#!/bin/bash
# 核心原则：原文照抄，只改错误，物理重写核心 MK 文件防止 Error 2
# 物理审计：1.修改IP 2.注册DTS 3.物理覆盖mt7981.mk 4.劫持U-Boot 5.激活开关

# 1. 物理修改 IP 地址
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# 2. 物理注册 DTS (锁定 24.10 内核路径)
DTS_MAKEFILE="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/Makefile"
if [ -f "$DTS_MAKEFILE" ]; then
    sed -i '/mt7981-sl-3000-emmc.dtb/d' "$DTS_MAKEFILE"
    sed -i '/mt7981-spim-nor-rfb/a \	mt7981-sl-3000-emmc.dtb \\' "$DTS_MAKEFILE"
fi

# 3. 物理重写 mt7981.mk (彻底解决 mt7981.mk: No such file or directory)
# 审计结论：直接将您的 sl_3000-emmc 定义强制注入源文件，确保物理存在且逻辑正确
MK_FILE="target/linux/mediatek/image/mt7981.mk"
cat <<EOF > $MK_FILE
KERNEL_LOADADDR := 0x48080000

MT7981_USB_PKGS := automount blkid blockdev fdisk \\
    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\
    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\
    kmod-usb-net-rndis usbutils \\
    kmod-usb-net-qmi-wwan autoksmbd

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := \$(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  IMAGES := sysupgrade.bin fip.bin
  IMAGE/fip.bin := append-metadata | pad-to 1M
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF

# 4. U-Boot 物理劫持 (1024M 引导链闭环)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\' "$UBOOT_MAKEFILE"
fi

# 5. 强制物理激活救砖包开关
sed -i '/CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc/d' .config
echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
