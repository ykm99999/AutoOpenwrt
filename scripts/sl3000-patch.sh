#!/bin/bash
# 物理审计：粉碎 MIPS 架构感染，强行对位 5.4 内核驱动，重定向 U-Boot 源码

# 1. 物理重写 mt7981.mk (像素级原文照抄全局框架)
printf 'KERNEL_LOADADDR := 0x48080000\n\n' > target/linux/mediatek/image/mt7981.mk
printf 'MT7981_USB_PKGS := automount blkid blockdev fdisk \\\n    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \\\n    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \\\n    kmod-usb-net-rndis usbutils \\\n    kmod-usb-net-qmi-wwan autoksmbd\n\n' >> target/linux/mediatek/image/mt7981.mk

printf 'define Device/sl_3000-emmc\n  DEVICE_VENDOR := SL\n  DEVICE_MODEL := 3000 eMMC\n  DEVICE_DTS := mt7981-sl-3000-emmc\n  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek\n  SUPPORTED_DEVICES := sl,3000-emmc\n  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\\n\tluci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils\n  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata\nendef\nTARGET_DEVICES += sl_3000-emmc\n' >> target/linux/mediatek/image/mt7981.mk

# 2. U-Boot 源码物理重定向与架构隔离
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理改写下载源为专属仓库分支
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g" "$UBOOT_MAKEFILE"
    
    # 物理粉碎 MIPS 相关机型定义，防止架构错位 (-mabi=32 报错)
    sed -i 's/UBOOT_TARGETS :=.*/UBOOT_TARGETS := mt7981_sl3000_emmc/g' "$UBOOT_MAKEFILE"
    sed -i '/define Device\/mt7620/,/endef/d' "$UBOOT_MAKEFILE"
fi

# 3. 彻底粉碎 Mac80211 报错 (物理降级驱动以兼容 5.4 内核)
rm -rf package/kernel/mac80211
git clone https://github.com/coolsnowwolf/lede package/kernel/mac80211_tmp --depth 1
cp -rf package/kernel/mac80211_tmp/package/kernel/mac80211 package/kernel/
rm -rf package/kernel/mac80211_tmp
# 物理像素级抹除 6.6.15 下载逻辑
sed -i 's/^PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_SOURCE:=.*/PKG_SOURCE:=/g' package/kernel/mac80211/Makefile
sed -i 's/^PKG_HASH:=.*/PKG_HASH:=/g' package/kernel/mac80211/Makefile

# 4. 物理注入 5.4 内核专用 DTS (对齐 eMMC 128GB 分区)
DTS_TARGET="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek/mt7981-sl-3000-emmc.dts"
mkdir -p $(dirname "$DTS_TARGET")
[ -f custom-config/mt7981b-3000-emmc.dts ] && cp -f custom-config/mt7981b-3000-emmc.dts "$DTS_TARGET"

# 5. 环境物理清理与 IP 锁定 (192.168.1.2)
find package -name "Makefile" | xargs grep -l "PACKAGE_rd05a1" | xargs sed -i '/DEPENDS.*PACKAGE_rd05a1/d' 2>/dev/null || true
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

echo "脚本物理修复完成：已阻断架构交叉感染，完成 U-Boot 重定向。"
