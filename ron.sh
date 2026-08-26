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
    echo "  1. 系统自动更新          auto-update"
    echo "  2. Caddy 安装卸载        caddy"
    echo "  3. nftables 防火墙       fw"
    echo "  4. 安装 XanMod 内核      xanmod"
    echo "  5. 网络参数优化          netopt"
    echo "  6. Singbox nftables      singbox"
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
