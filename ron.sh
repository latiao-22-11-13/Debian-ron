#!/usr/bin/env bash
# Ron 工具箱一键菜单 (基于 Ronlam22/Debian 脚本合集)
BASE="https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main"
CDN="https://cdn.jsdelivr.net/gh/latiao-22-11-13/Debian-ron@main"

run() {
  echo ""
  echo ">>> 正在运行 $1 ..."
  echo ""
  bash <(curl -fsSL "$BASE/$1" || curl -fsSL "$CDN/$1")
  echo ""
  echo ">>> $1 运行结束"
  read -rp "按回车返回菜单..." _
}

menu() {
  while true; do
    clear
    echo "======================================"
    echo "         Ron 工具箱 (Debian)"
    echo "======================================"
    echo "  1. 系统自动更新          ron-update"
    echo "        apt 升级 + 清理旧内核,系统更省心"
    echo ""
    echo "  2. Caddy 安装卸载        ron-caddy"
    echo "        自动 HTTPS 的 Web/反代服务器"
    echo ""
    echo "  3. nftables 防火墙       ron-fw"
    echo "        nftables 规则 + 端口同步(防扫描)"
    echo ""
    echo "  4. 安装 XanMod 内核      ron-xanmod"
    echo "        升级到 XanMod main,性能更强"
    echo ""
    echo "  5. 网络参数优化          ron-netopt"
    echo "        BBR + 缓冲区 + 防休眠,跑满带宽"
    echo ""
    echo "  6. Singbox nftables      ron-singbox"
    echo "        Sing-box 出站 nftables 配置"
    echo ""
    echo "  0. 退出"
    echo "======================================"
    read -rp "请选择 [0-6]: " c
    case $c in
      1) run auto-update.sh ;;
      2) run caddy-manager.sh ;;
      3) run fw.sh ;;
      4) run install-xanmod.sh ;;
      5) run net-optimization.sh ;;
      6) run switch_nftable.sh ;;
      0) exit 0 ;;
    esac
  done
}

case "$1" in
  "") menu ;;
  -h|--help|help)
    echo "用法: ron            打开交互菜单"
    echo "      ron <命令>     直接运行"
    echo "命令: update | caddy | fw | xanmod | netopt | singbox" ;;
  update) run auto-update.sh ;;
  caddy) run caddy-manager.sh ;;
  fw) run fw.sh ;;
  xanmod) run install-xanmod.sh ;;
  netopt) run net-optimization.sh ;;
  singbox) run switch_nftable.sh ;;
  *) echo "未知命令: $1 (可用: update caddy fw xanmod netopt singbox)"; exit 1 ;;
esac
