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

### 快捷命令一览

| 命令 | 作用 | 什么时候用 |
|---|---|---|
| `ron` | 打开交互式菜单 | 不记得命令名时，用菜单点选即可 |
| `ron-update` | 系统自动更新 (`auto-update.sh`) | 日常跑 `apt upgrade`，自动清理旧内核 |
| `ron-caddy` | Caddy 安装/卸载 (`caddy-manager.sh`) | 需要 Web 服务器或反向代理（自动 HTTPS）时 |
| `ron-fw` | nftables 防火墙 (`fw.sh`) | 给 VPS 配端口同步/防扫描，或远程开端口 |
| `ron-xanmod` | 安装 XanMod main 内核 (`install-xanmod.sh`) | 系统装好第一件事，跑生产环境更稳更快 |
| `ron-netopt` | 网络参数优化 (`net-optimization.sh`) | 开启 BBR、调整缓冲区，让带宽跑满 |
| `ron-singbox` | Singbox nftables 配 (`switch_nftable.sh`) | 搭配代理节点，自动出站分流规则 |

> 提示：脚本运行时会自己用 `sudo` 提权，首次需要输入当前用户密码。

### 也可以不装别名，单独直接运行某个脚本

> 把鼠标停在下面任一条目右上角会显示一个 **复制按钮**，点一下整行 URL 就到剪贴板了，再贴到终端即可。

系统自动更新 — apt 升级 + 清理旧内核

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/auto-update.sh
```

Caddy 安装/卸载 — 自动 HTTPS 的 Web/反代服务器

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/caddy-manager.sh
```

nftables 防火墙 — 端口同步、防扫描、远程开关

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/fw.sh
```

安装 XanMod main 内核 — 比 Debian 默认内核性能更好

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/install-xanmod.sh
```

网络参数优化 — 开启 BBR + 调整缓冲区

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/net-optimization.sh
```

Singbox nftables 配置 — 代理节点出站分流

```bash
https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main/switch_nftable.sh
```

> 国内 VPS 若访问 raw 失败，把链接前缀换成：`https://cdn.jsdelivr.net/gh/latiao-22-11-13/Debian-ron@main`

---

## 🔄 自动同步上游

本 fork 通过 GitHub Actions 每天自动从上游 [Ronlam22/Debian](https://github.com/Ronlam22/Debian) 同步更新（北京时间每天 03:17），也可在 Actions 页面手动触发。若自动合并出现冲突，会创建 Issue 提醒手动处理。
