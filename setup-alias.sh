#!/usr/bin/env bash
# 一键安装 ron 快捷命令别名 (写入 ~/.bashrc)
R="https://raw.githubusercontent.com/latiao-22-11-13/Debian-ron/main"
RC="$HOME/.bashrc"

sed -i '/# >>> ron aliases >>>/,/# <<< ron aliases <<</d' "$RC" 2>/dev/null

cat >> "$RC" <<EOF
# >>> ron aliases >>>
alias ron='bash <(curl -fsSL $R/ron.sh)'
alias ron-update='bash <(curl -fsSL $R/auto-update.sh)'
alias ron-caddy='bash <(curl -fsSL $R/caddy-manager.sh)'
alias ron-fw='bash <(curl -fsSL $R/fw.sh)'
alias ron-xanmod='bash <(curl -fsSL $R/install-xanmod.sh)'
alias ron-netopt='bash <(curl -fsSL $R/net-optimization.sh)'
alias ron-singbox='bash <(curl -fsSL $R/switch_nftable.sh)'
# <<< ron aliases <<<
EOF

echo "快捷命令已安装!"
echo "立即生效请执行: source ~/.bashrc"
echo "之后可用: ron (菜单) | ron-update | ron-caddy | ron-fw | ron-xanmod | ron-netopt | ron-singbox"
