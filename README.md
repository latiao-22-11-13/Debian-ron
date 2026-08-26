安装环境Debian13

auto-update.sh  自动更新最新版本脚本
caddy-manager.sh  Caddy安装卸载脚本
fw.sh  nftables  防火墙配置脚本
install-komari.sh  一键安装Komari面板
uninstall-komari.sh  完全卸载Komari面板及相关配置
install-xanmod.sh  一键安装XanMod main内核
net-optimization.sh  网络参数优化脚本
switch_nftable.sh  Singbox nftables配置脚本

---

## 🚀 VPS 一键使用（本 fork 增强菜单与快捷命令）

### 一键打开工具箱菜单

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/ron.sh)
```

### 安装快捷命令（推荐，VPS 上粘贴一次永久生效）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/setup-alias.sh) && source ~/.bashrc
```

安装后可用快捷命令：

| 快捷命令 | 功能 |
|---|---|
| `ron` | 打开交互式工具箱菜单 |
| `ron-update` | 系统自动更新 (auto-update.sh) |
| `ron-caddy` | Caddy 安装卸载 (caddy-manager.sh) |
| `ron-fw` | nftables 防火墙配置 (fw.sh) |
| `ron-xanmod` | 安装 XanMod main 内核 (install-xanmod.sh) |
| `ron-netopt` | 网络参数优化 (net-optimization.sh) |
| `ron-singbox` | Singbox nftables 配置 (switch_nftable.sh) |

也可以不装别名，单独直接运行某个脚本：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/auto-update.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/caddy-manager.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/fw.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/install-xanmod.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/net-optimization.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/switch_nftable.sh)
```

> 国内 VPS 若访问 raw 失败，把链接前缀换成：`https://cdn.jsdelivr.net/gh/latiao-22-11-13/Debian-ron@main`

---

## 🔄 自动同步上游

本 fork 通过 GitHub Actions 每天自动从上游 [Ronlam22/Debian](https://github.com/Ronlam22/Debian) 同步更新（北京时间每天 03:17），也可在 Actions 页面手动触发。若自动合并出现冲突，会创建 Issue 提醒手动处理。
