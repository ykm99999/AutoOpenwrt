# 司络 SL-3000 固件说明文档

## 📡 路由器硬件配置
- **型号**：司络 SL-3000 (MT7981 平台)
- **CPU**：联发科 MT7981 双核
- **内存**：512MB DDR4
- **闪存**：128MB NAND
- **无线**：Wi-Fi 6 (2.4GHz + 5GHz)
- **接口**：
  - 1 × WAN 千兆口
  - 3 × LAN 千兆口
- **电源**：DC 12V / 2A

---

## ⚙️ 固件配置
- **固件版本**：ImmortalWrt 24.10 稳定版
- **内核版本**：Linux 6.6 LTS
- **编译方式**：GitHub Actions 自动编译
- **默认管理地址**：`192.168.6.1`
- **自定义品牌**：
  - LuCI Web 界面顶部 Logo：`司络 SL-3000`
  - 登录 Banner：`Welcome to 司络 SL-3000 ImmortalWrt`

---

## 📦 软件包配置

### 🔹 网络代理
- `luci-app-passwall2`  
- `passwall2-core`  
- `passwall2-ss` / `passwall2-ssr`  
- `passwall2-v2ray` / `passwall2-xray`  
- `passwall2-trojan`  
- 可选增强：`passwall2-chinadns-ng`、`passwall2-dns2socks`

### 🔹 系统工具
- `luci-app-docker`（Docker 管理界面）
- `luci-app-attendedsysupgrade`（在线升级）
- `luci-app-opkg`（软件包管理）
- `luci-app-firewall`（防火墙配置）

### 🔹 网络服务
- `luci-app-samba4`（文件共享）
- `luci-app-upnp`（端口自动映射）
- `luci-app-ddns`（动态域名解析）

### 🔹 网络加速
- `luci-app-turboacc`（LuCI 界面一键加速）
- `kmod-ipt-offload`（Flow Offload 软件加速）
- `kmod-shortcut-fe` / `kmod-shortcut-fe-cm`（Shortcut-FE 高性能转发引擎）
- `kmod-nft-fullcone`（FullCone NAT 支持）
- `kmod-tcp-bbr`（TCP BBR 拥塞控制）

### 🔹 其他
- `luci-i18n-base-zh-cn`（中文界面支持）
- `luci-theme-bootstrap`（默认主题，可替换 Logo）

---

## 🚀 使用说明
1. 登录 Web 界面：`http://192.168.6.1`  
2. 默认用户名：`root`  
3. 默认密码：空（首次登录需设置密码）  
4. 在 **服务 → PassWall2** 中配置代理节点和策略组  
5. 在 **系统 → Docker** 中管理容器  
6. 在 **系统 → Turbo ACC** 中开启网络加速  
7. 在 **系统 → 软件包** 中安装或更新其他功能  

---

## 📌 注意事项
- 建议刷机后立即修改管理密码  
- 使用代理功能时，请合理配置 DNS 分流，避免节点失效  
- 网络加速功能可能与部分代理冲突，建议逐项测试  
- Logo 文件支持 PNG/JPEG，推荐透明背景 PNG，尺寸 120–200px × 40–60px
