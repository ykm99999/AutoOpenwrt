#
# Copyright (C) 2020-2024 MediaTek Inc.
# Copyright (C) 2024 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# 常用软件包定义（可根据需要调整）
MT7981_USB_PKGS := automount blkid blockdev fdisk \
    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \
    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \
    kmod-usb-net-rndis usbutils \
    kmod-usb-net-qmi-wwan autoksmbd

# --- 标准版设备定义（示例，可根据实际情况修改）---
define Device/sl_3000
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_DTS := mt7981-sl-3000
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000

# --- eMMC 1024M 物理全对齐定义（已修复 initramfs 问题）---
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils

  # 关键修复：覆盖内核生成规则，跳过 initramfs 构建
  KERNEL := kernel-bin | fit none
  KERNEL_INITRAMFS :=                # 留空，彻底不构建 initramfs

  # 仅生成 sysupgrade 固件，避免多余镜像
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  # 注释 ARTIFACTS 以避免 mtk-gpt 缺失错误（如需救砖文件可另行处理）
  # ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  # ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  # ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  # ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
endef
TARGET_DEVICES += sl_3000-emmc

# 可在此添加其他设备定义...
