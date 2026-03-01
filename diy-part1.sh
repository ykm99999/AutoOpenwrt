#!/bin/bash
# 只移除导致 24.10 内核物理冲突的 mt76 源码
# 保留基础 mac80211 依赖，防止出现 kmod-appletalk 等缺失警报
rm -rf package/kernel/mt76
