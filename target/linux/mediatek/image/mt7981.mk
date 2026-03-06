#
# Target Makefile for MediaTek Filogic 820 (MT7981) - Full Aligned for SL-3000
#

KERNEL_LOADADDR := 0x48080000

# 常用软件包
MT7981_USB_PKGS := automount blkid blockdev fdisk \
    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \
    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \
    kmod-usb-net-rndis usbutils \
    kmod-usb-net-qmi-wwan autoksmbd

# --- 标准版定义 ---
define Device/sl_3000
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_DTS := mt7981-sl-3000
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000

# --- eMMC 1024M 物理全对齐定义 ---
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  
  # 物理修复：仅保留 sysupgrade，不再触发对 fip.bin 的复合后缀 dd 签名
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  # 物理生成：救砖全家桶 (GPT + Preloader + U-Boot FIP)
  # 审计：ARTIFACTS 生成的文件名固定，100% 避开 Error 1 熔断
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
endef
TARGET_DEVICES += sl_3000-emmc
