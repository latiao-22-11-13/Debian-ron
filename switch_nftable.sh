#!/bin/bash
set -Eeuo pipefail
umask 077

TARGET_CONF="/etc/nftables.conf"
LOCK_FILE="/run/lock/switch_nftable.lock"
TEMP_CONF=""

clear_screen() {
    if [[ -t 1 ]]; then
        if command -v tput >/dev/null 2>&1 && tput clear 2>/dev/null; then
            return 0
        fi
        printf '\033[2J\033[H'
    fi
}

print_section() {
    printf '%s\n' \
        '========================================================' \
        "          $1" \
        '========================================================'
}

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

cleanup() {
    local status=$?
    if [[ -n "$TEMP_CONF" ]]; then
        rm -f -- "$TEMP_CONF" || true
    fi
    return "$status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

read_line() {
    local prompt=$1 default=${2-}
    IFS= read -r -e -p "$prompt" REPLY || die "输入已结束，未切换配置。"
    REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
    REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"
    REPLY=${REPLY:-$default}
}

valid_port() {
    [[ $1 =~ ^[0-9]{1,5}$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 ))
}

valid_ipv4_cidr() {
    local address prefix octet
    local -a octets
    [[ $1 =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})$ ]] || return 1
    address=${BASH_REMATCH[1]}
    prefix=${BASH_REMATCH[2]}
    (( 10#$prefix <= 32 )) || return 1
    IFS=. read -r -a octets <<< "$address"
    for octet in "${octets[@]}"; do
        (( 10#$octet <= 255 )) || return 1
    done
}

valid_ipv6_cidr() {
    local address prefix
    [[ $1 =~ ^([[:xdigit:]:.]+)/([0-9]{1,3})$ ]] || return 1
    address=${BASH_REMATCH[1]}
    prefix=${BASH_REMATCH[2]}
    [[ $address == *:* ]] && (( 10#$prefix <= 128 ))
}

(( EUID == 0 )) || die "请使用 root 或 sudo 运行。"
for cmd in nft ps awk sort mktemp mv chmod rm flock readlink; do
    command -v "$cmd" >/dev/null 2>&1 || die "缺少命令：$cmd"
done
exec 9>"$LOCK_FILE"
flock -n 9 || die "已有另一份切换脚本正在运行。"

clear_screen

print_section '请选择代理模式'
printf '%s\n' \
    '1) 全局模式(Global Mode —— 仅指定目标直连，其余全部代理)' \
    '2) 规则模式(Rule Mode   —— 仅 FakeIP、Telegram、指定 DNS 53 端口走代理)' \
    '0) 退出'
read_line '输入选项 [0-2]: '
case "$REPLY" in
    0) printf '%s\n' '已退出。'; exit 0 ;;
    1) MODE=global; MODE_NAME=全局模式 ;;
    2) MODE=rule; MODE_NAME=规则模式 ;;
    *) die "无效选项。" ;;
esac

printf '\n'
print_section '请选择透明代理实现方式'
printf '%s\n' \
    '1) 混合模式     —— (TCP Redirect + UDP TPROXY)' \
    '2) 纯TPROXY模式 —— (TCP + UDP TPROXY)' \
    '0) 退出'
read_line '输入选项 [0-2]: '
case "$REPLY" in
    0) printf '%s\n' '已退出。'; exit 0 ;;
    1) IMPL=hybrid; IMPL_NAME=混合模式; PROTOCOLS=(udp); PROTOCOL_MATCH=udp ;;
    2) IMPL=pure; IMPL_NAME=纯TPROXY模式; PROTOCOLS=(tcp udp); PROTOCOL_MATCH='{ tcp, udp }' ;;
    *) die "无效选项。" ;;
esac

printf '\n'
print_section '端口与Fake-IP参数设置'
read_line '请输入Redirect端口(默认9777): ' 9777
valid_port "$REPLY" || die "Redirect 端口必须为 1–65535 的整数。"
REDIRECT_PORT=$((10#$REPLY))

read_line '请输入TPROXY端口(默认9888): ' 9888
valid_port "$REPLY" || die "TPROXY 端口必须为 1–65535 的整数。"
TPROXY_PORT=$((10#$REPLY))

read_line '请输入Fake_ipv4网段(默认28.0.0.0/8): ' '28.0.0.0/8'
valid_ipv4_cidr "$REPLY" || die "FakeIP IPv4 网段格式错误。"
FAKE_IPV4_CIDR=$REPLY

read_line '请输入Fake_ipv6网段(默认2001:2::/64): ' '2001:2::/64'
valid_ipv6_cidr "$REPLY" || die "FakeIP IPv6 网段格式错误。"
FAKE_IPV6_CIDR=$REPLY

mapfile -t SINGBOX_GIDS < <(ps -o egid= -C sing-box,singbox 2>/dev/null | awk '$1 ~ /^[0-9]+$/ { print $1 }' | sort -nu || true)
if (( ${#SINGBOX_GIDS[@]} == 0 )); then
    SINGBOX_GIDS=(0)
    printf '%s\n' '未检测到运行中的 sing-box，沿用默认 GID 0 防回环。' >&2
fi
if (( ${#SINGBOX_GIDS[@]} == 1 )); then
    SINGBOX_GID=${SINGBOX_GIDS[0]}
else
    SINGBOX_GID="{ $(IFS=,; printf '%s' "${SINGBOX_GIDS[*]}") }"
fi

printf '\n'
print_section '将使用配置'
printf '  代理模式      : %s\n' "$MODE_NAME"
printf '  实现方式      : %s\n' "$IMPL_NAME"
printf '  Redirect端口  : %s\n' "$REDIRECT_PORT"
printf '  TPROXY端口    : %s\n' "$TPROXY_PORT"
printf '  fake_ipv4     : %s\n' "$FAKE_IPV4_CIDR"
printf '  fake_ipv6     : %s\n' "$FAKE_IPV6_CIDR"
printf '  绕过 GID      : %s\n' "$SINGBOX_GID"
printf '  策略路由      : mark 1 (IPv4/IPv6)\n'
if [[ $IMPL == pure ]]; then
    printf '\n此模式要求 sing-box 的 TPROXY 入站在 %s 同时监听 TCP 和 UDP。\n' "$TPROXY_PORT"
fi

emit_rule() {
    printf '        %s\n' "$*"
}

emit_bypass() {
    emit_rule 'ip daddr @local_ipv4 return'
    emit_rule 'ip6 daddr @local_ipv6 return'
    if [[ $MODE == global ]]; then
        emit_rule 'ip daddr @china_dns_ipv4 return'
        emit_rule 'ip6 daddr @china_dns_ipv6 return'
    fi
    emit_rule 'fib daddr type { unspec, local, broadcast, anycast, multicast } return'
}

emit_fake_redirect() {
    emit_rule "ip daddr @fake_ipv4 meta l4proto tcp redirect to :$REDIRECT_PORT"
    emit_rule "ip6 daddr @fake_ipv6 meta l4proto tcp redirect to :$REDIRECT_PORT"
}

emit_tproxy_rule() {
    local match=$1 family=${2-}
    emit_rule "$match meta mark set 1 tproxy${family:+ $family} to :$TPROXY_PORT accept"
}

emit_config() {
    local proto family suffix
    cat <<EOF
add table inet singbox
delete table inet singbox

table inet singbox {
    set fake_ipv4 {
        type ipv4_addr;
        flags interval;
        elements = { $FAKE_IPV4_CIDR };
    }
    set fake_ipv6 {
        type ipv6_addr;
        flags interval;
        elements = { $FAKE_IPV6_CIDR };
    }
    set local_ipv4 {
        type ipv4_addr;
        flags interval;
        elements = { 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 };
    }
    set local_ipv6 {
        type ipv6_addr;
        flags interval;
        elements = { ::ffff:0.0.0.0/96, 64:ff9b::/96, 100::/64, 2001:10::/28, 2001:20::/28, 2001:db8::/32, 2002::/16, fe80::/10, fc00::/7, ff00::/8 };
    }
EOF
    if [[ $MODE == global ]]; then
        cat <<'EOF'
    set china_dns_ipv4 {
        type ipv4_addr;
        elements = { 223.5.5.5, 223.6.6.6, 114.114.114.114, 114.114.115.115 };
    }
    set china_dns_ipv6 {
        type ipv6_addr;
        elements = { 2400:3200::1, 2400:3200:baba::1 };
    }
EOF
    else
        cat <<'EOF'
    set remote_dns_ipv4 {
        type ipv4_addr;
        elements = { 8.8.8.8, 8.8.4.4, 1.1.1.1, 1.0.0.1 };
    }
    set remote_dns_ipv6 {
        type ipv6_addr;
        elements = { 2001:4860:4860::8888, 2001:4860:4860::8844, 2606:4700:4700::1111, 2606:4700:4700::1001 };
    }
    set telegram_ipv4 {
        type ipv4_addr;
        flags interval;
        elements = { 5.28.192.0/18, 67.198.55.0/24, 91.105.192.0/23, 91.108.0.0/16, 95.161.64.0/20, 109.239.140.0/24, 139.59.210.98/32, 149.154.160.0/20, 185.76.151.0/24, 196.55.216.167/32, 216.239.30.0/24 };
    }
    set telegram_ipv6 {
        type ipv6_addr;
        flags interval;
        elements = { 2001:67c:4e8::/48, 2001:b28:f23c::/47, 2001:b28:f23f::/48, 2a0a:f280::/29 };
    }
EOF
    fi
    if [[ $IMPL == hybrid ]]; then
        printf '    chain redirect-proxy {\n'
        emit_fake_redirect
        emit_bypass
        if [[ $MODE == global ]]; then
            emit_rule "meta l4proto tcp redirect to :$REDIRECT_PORT"
        else
            for family in ip ip6; do
                [[ $family == ip ]] && suffix=4 || suffix=6
                emit_rule "$family daddr @telegram_ipv$suffix meta l4proto tcp redirect to :$REDIRECT_PORT"
                emit_rule "$family daddr @remote_dns_ipv$suffix tcp dport 53 redirect to :$REDIRECT_PORT"
            done
        fi
        cat <<'EOF'
    }
    chain redirect-prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        meta l4proto != tcp return
        ct state new ct direction original goto redirect-proxy
    }
    chain redirect-output {
        type nat hook output priority dstnat; policy accept;
        meta l4proto != tcp return
EOF
        if [[ $MODE == global ]]; then
            emit_fake_redirect
        else
            emit_rule "meta skgid $SINGBOX_GID return"
            emit_rule 'ct direction original goto redirect-proxy'
        fi
        printf '    }\n'
    fi
    printf '    chain tproxy-proxy {\n'
    for proto in "${PROTOCOLS[@]}"; do
        emit_tproxy_rule "ip daddr @fake_ipv4 meta l4proto $proto" ip
        emit_tproxy_rule "ip6 daddr @fake_ipv6 meta l4proto $proto" ip6
    done
    if [[ $MODE == global ]]; then
        emit_rule 'udp dport 123 return'
    fi
    emit_bypass
    for proto in "${PROTOCOLS[@]}"; do
        if [[ $MODE == global ]]; then
            emit_tproxy_rule "meta l4proto $proto"
        else
            for family in ip ip6; do
                [[ $family == ip ]] && suffix=4 || suffix=6
                emit_tproxy_rule "$family daddr @telegram_ipv$suffix meta l4proto $proto" "$family"
                emit_tproxy_rule "$family daddr @remote_dns_ipv$suffix meta l4proto $proto $proto dport 53" "$family"
            done
        fi
    done
    cat <<'EOF'
    }
    chain tproxy-mark {
        ip daddr @fake_ipv4 meta mark set 1 return
        ip6 daddr @fake_ipv6 meta mark set 1 return
EOF
    if [[ $MODE == global ]]; then
        emit_rule 'udp dport 123 return'
    fi
    emit_bypass
    if [[ $MODE == global ]]; then
        emit_rule 'meta mark set 1'
    else
        for family in ip ip6; do
            [[ $family == ip ]] && suffix=4 || suffix=6
            emit_rule "$family daddr @telegram_ipv$suffix meta mark set 1 return"
            for proto in "${PROTOCOLS[@]}"; do
                emit_rule "$family daddr @remote_dns_ipv$suffix $proto dport 53 meta mark set 1 return"
            done
        done
    fi
    cat <<EOF
    }
    chain tproxy-prerouting {
        type filter hook prerouting priority mangle; policy accept;
        meta l4proto != $PROTOCOL_MATCH return
        ct direction original goto tproxy-proxy
    }
    chain tproxy-output {
        type route hook output priority mangle; policy accept;
        meta l4proto != $PROTOCOL_MATCH return
        meta skgid $SINGBOX_GID return
        ct direction original goto tproxy-mark
    }
}
EOF
}

printf '\n'
print_section '正在校验并应用 nftables 规则'
TARGET_CONF=$(readlink -f -- "$TARGET_CONF") || die "无法解析配置路径。"
[[ ! -e "$TARGET_CONF" || -f "$TARGET_CONF" ]] || die "配置路径不是普通文件。"
TEMP_CONF=$(mktemp "${TARGET_CONF}.new.XXXXXX")
emit_config > "$TEMP_CONF"
nft -c -f "$TEMP_CONF" || die "配置校验失败，现有配置和运行规则未修改。"
chmod 644 "$TEMP_CONF"

nft -f "$TEMP_CONF" || die "规则加载失败，原配置文件未修改。请检查运行时规则状态。"
mv -fT -- "$TEMP_CONF" "$TARGET_CONF" || die "规则已加载，但保存到 $TARGET_CONF 失败。"
TEMP_CONF=""

printf '规则已加载：%s\n' "$TARGET_CONF"
if command -v systemctl >/dev/null 2>&1; then
    if ! systemctl is-enabled --quiet nftables.service; then
        systemctl enable nftables.service || die "规则已加载并保存，但启用 nftables 开机自启失败。"
    fi
    printf '%s\n' 'nftables 开机自启已启用。'
else
    printf '%s\n' '未发现 systemctl；规则已加载并保存，开机加载请沿用现有机制。'
fi
printf '\n%s\n' '操作完成。'
