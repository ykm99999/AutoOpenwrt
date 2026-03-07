define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  # 注释 ARTIFACTS 避免 mtk-gpt 缺失错误
  # ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  # ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  # ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  # ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
endef
TARGET_DEVICES += sl_3000-emmc
