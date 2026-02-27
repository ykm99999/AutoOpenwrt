#!/bin/bash
# File name: scripts/sl3000-patch.sh
# 审计：物理精简，不再重写 Makefile，仅微调 IP。

# 1. 基础配置物理对齐 (原文照抄原则)
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 物理熔断递归依赖死锁 (rd05a1)
# 针对 5.4 内核在 24.10 环境下的兼容性修复
find package -name "Makefile" | xargs grep -l "PACKAGE_rd05a1" | xargs sed -i '/DEPENDS.*PACKAGE_rd05a1/d' 2>/dev/null || true

echo "24.10 源码 + 5.4 内核 脚本执行完毕。"
