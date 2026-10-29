#!/usr/bin/env bash
#
# archBegin.sh —— Arch Linux 桌面环境初始化脚本
# 目标：niri + DankMaterialShell（DMS）桌面，附带常用软件、中文输入法与常用配置
#
# 用法：
#   ./archBegin.sh          # 以普通用户运行（需要 sudo 权限）
#
# 脚本是幂等的：已安装的包会跳过，niri 配置只在缺少对应片段时追加，
# 不会覆盖你已有的自定义配置。
#
set -euo pipefail

# ---------------------------------------------------------------------------
# 包列表
#   官方仓库里有的走 pacman，找不到的自动落到 AUR
# ---------------------------------------------------------------------------
PKGS=(
    # ---- 桌面环境 / 合成器 ----
    niri
    xwayland-satellite
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
    dms-shell-niri
    quickshell
    matugen
    cava
    qt6-multimedia-ffmpeg

    # ---- 基础软件 ----
    networkmanager
    nm-connection-editor
    firefox
    git
    base-devel
    # 官方 Microsoft 构建，设置同步需要它（OSS 版 code 不支持）
    visual-studio-code-bin
    onlyoffice-bin
    wechat-bin
    linuxqq
    ghostty
    alacritty
    fish
    xdg-terminal-exec
    xdg-user-dirs
    xdg-user-dirs-gtk

    # ---- GNOME 系统设置（含“用户”账号管理面板）----
    gnome-control-center

    # ---- niri 配置里用到的启动器 / 锁屏 / 权限代理 ----
    fuzzel
    swaylock
    polkit-gnome
    gnome-keyring
    libsecret

    # ---- 截图 / 剪贴板 ----
    grim
    slurp
    satty
    wl-clipboard
    cliphist

    # ---- 中文输入法 ----
    fcitx5
    fcitx5-chinese-addons
    fcitx5-gtk
    fcitx5-qt
    fcitx5-configtool

    # ---- 音频 / 蓝牙 / 电源 ----
    pavucontrol
    playerctl
    wireplumber
    pipewire-pulse
    gst-plugin-pipewire
    gst-libav
    gst-plugins-good
    bluez
    bluez-utils
    blueman
    power-profiles-daemon
    brightnessctl

    # ---- 文件管理 / 归档 ----
    nautilus
    file-roller
    7zip
    unzip
    unrar
    gvfs
    gvfs-mtp
    gvfs-smb
    gvfs-gphoto2
    udisks2
    gnome-disk-utility

    # ---- 字体 ----
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-jetbrains-mono-nerd

    # ---- 命令行工具 ----
    fd
    ripgrep
    fzf
    zoxide
    bat
    eza
    btop
    fastfetch
    starship
    jq
    pacman-contrib

    # ---- 媒体 ----
    mpv
    imv

    # ---- 系统维护 ----
    fwupd

    # ---- 游戏 ----
    steam
)

# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

OFFICIAL_PKGS=()
AUR_PKGS=()
AUR_HELPER=""

NIRI_DIR="$HOME/.config/niri"
NIRI_CONFIG="$NIRI_DIR/config.kdl"
NIRI_BACKUP_DONE=0

check_environment() {
    [[ $EUID -ne 0 ]] || die "请不要用 root 运行本脚本（AUR 构建和 systemctl --user 都需要普通用户）"

    [[ -f /etc/arch-release ]] || die "这个脚本只适用于 Arch Linux"
    command -v sudo >/dev/null 2>&1 || die "缺少 sudo，请先安装：pacman -S sudo"

    if ! sudo -v; then
        die "sudo 鉴权失败"
    fi

    # 保持 sudo 凭证有效，避免脚本中途反复输密码
    while true; do
        sudo -n true 2>/dev/null || exit
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

ensure_multilib() {
    grep -q '^\[multilib\]' /etc/pacman.conf && return 0

    log "启用 multilib 仓库（steam 依赖）"
    # [multilib] 下一行通常是被注释掉的 Include
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf

    grep -q '^\[multilib\]' /etc/pacman.conf \
        || die "自动启用 multilib 失败，请手动编辑 /etc/pacman.conf"
    sudo pacman -Sy --noconfirm
}

ensure_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER=$(command -v paru)
        return 0
    fi
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER=$(command -v yay)
        return 0
    fi

    log "未检测到 AUR 助手，开始安装 yay ..."
    sudo pacman -S --needed --noconfirm base-devel git

    local tmp
    tmp=$(mktemp -d)
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
    ( cd "$tmp/yay" && makepkg -si --noconfirm )
    rm -rf "$tmp"

    AUR_HELPER=$(command -v yay) || die "yay 安装失败"
}

classify_packages() {
    local pkg
    for pkg in "${PKGS[@]}"; do
        # 普通包用 -Si 判断；base-devel 这类包组用 -Sg 判断
        if pacman -Si "$pkg" >/dev/null 2>&1 || pacman -Sg "$pkg" >/dev/null 2>&1; then
            OFFICIAL_PKGS+=("$pkg")
        else
            AUR_PKGS+=("$pkg")
        fi
    done

    log "官方仓库包：${#OFFICIAL_PKGS[@]} 个"
    log "AUR 包：${#AUR_PKGS[@]} 个${AUR_PKGS[*]:+ (${AUR_PKGS[*]})}"
}

install_packages() {
    if [[ ${#OFFICIAL_PKGS[@]} -gt 0 ]]; then
        log "安装官方仓库软件包 ..."
        sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"
    fi

    if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
        ensure_aur_helper

        # visual-studio-code-bin 与官方仓库的 code 冲突，按需移除
        if printf '%s\n' "${AUR_PKGS[@]}" | grep -qx 'visual-studio-code-bin' \
            && pacman -Qq code >/dev/null 2>&1; then
            log "移除 code（与 visual-studio-code-bin 冲突）"
            sudo pacman -Rns --noconfirm code
        fi

        log "从 AUR 安装剩余软件包 ..."
        if ! "$AUR_HELPER" -S --needed --noconfirm "${AUR_PKGS[@]}"; then
            warn "部分 AUR 软件包安装失败，请稍后手动执行："
            warn "  $AUR_HELPER -S ${AUR_PKGS[*]}"
        fi
    fi
}

configure_system() {
    log "启用系统服务（NetworkManager / Bluetooth / 电源管理）"
    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now bluetooth 2>/dev/null || warn "Bluetooth 服务启用失败，跳过"
    sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
    sudo systemctl enable --now fstrim.timer 2>/dev/null || true

    log "初始化用户目录（下载 / 文档 / 图片等）"
    xdg-user-dirs-update --force

    log "将默认 shell 切换为 fish"
    if [[ $SHELL != */fish ]]; then
        chsh -s "$(command -v fish)" "$USER"
    fi
}

configure_input_method() {
    log "配置 fcitx5 环境变量"
    mkdir -p "$HOME/.config/environment.d"
    cat > "$HOME/.config/environment.d/95-fcitx5.conf" <<'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
GLFW_IM_MODULE=ibus
EOF

    # 首次使用时直接带好「拼音」输入法，省得再手动添加
    if [[ ! -f "$HOME/.config/fcitx5/profile" ]]; then
        log "写入 fcitx5 默认输入法配置（键盘 + 拼音）"
        mkdir -p "$HOME/.config/fcitx5"
        cat > "$HOME/.config/fcitx5/profile" <<'EOF'
[Groups/0]
# Group Name
Name=默认
# Layout
Default Layout=us
# Default Input Method
DefaultIM=pinyin

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
# Layout=

[Groups/0/Items/1]
# Name
Name=pinyin
# Layout
# Layout=

[GroupOrder]
0=默认
EOF
    fi
}

# ---------------------------------------------------------------------------
# niri 配置
# ---------------------------------------------------------------------------

niri_backup_once() {
    (( NIRI_BACKUP_DONE )) && return 0
    local bak="$NIRI_CONFIG.bak-$(date +%Y%m%d-%H%M%S)"
    cp -a "$NIRI_CONFIG" "$bak"
    log "已备份 niri 配置：$bak"
    NIRI_BACKUP_DONE=1
}

append_to_niri() {
    niri_backup_once
    printf '\n%s\n' "$1" >> "$NIRI_CONFIG"
}

# 只有配置里不存在 needle 时才追加 line
ensure_niri_line() {
    local needle=$1 line=$2
    grep -qF -- "$needle" "$NIRI_CONFIG" && return 0
    append_to_niri "$line"
    log "niri 配置追加：$line"
}

ensure_niri_include() {
    local rel=$1
    [[ -f "$NIRI_DIR/$rel" ]] || return 0
    ensure_niri_line "include \"$rel\"" "include \"$rel\""
}

deploy_niri_config() {
    mkdir -p "$NIRI_DIR"

    if [[ ! -f "$NIRI_CONFIG" ]]; then
        log "未发现 niri 配置，使用 DMS 无交互模板生成 ..."
        if ! dms setup headless --compositor niri --terminal ghostty; then
            warn "dms setup headless 失败，将只写入本脚本的基础配置"
            : > "$NIRI_CONFIG"
        fi
    fi

    # DMS 生成的文件，存在才 include，避免 niri 因缺文件报错
    local rel
    for rel in dms/windowrules.kdl dms/cursor.kdl dms/layout.kdl \
               dms/outputs.kdl dms/input.kdl dms/binds.kdl; do
        ensure_niri_include "$rel"
    done
}

configure_niri_extras() {
    log "补齐 niri 常用配置（输入法自启 / 环境变量 / 触摸板 / 热角）"

    # fcitx5 随 niri 启动
    ensure_niri_line 'spawn-at-startup "fcitx5" "-d"' \
        'spawn-at-startup "fcitx5" "-d"'

    # polkit 认证代理，否则图形程序提权时不会弹窗
    ensure_niri_line 'polkit-gnome-authentication-agent-1' \
        'spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"'

    # 只在整个配置里没有 environment 节点时追加，避免重复节点
    if ! grep -q '^[[:space:]]*environment[[:space:]]*{' "$NIRI_CONFIG"; then
        append_to_niri 'environment {
    XMODIFIERS "@im=fcitx"
    QT_IM_MODULE "fcitx"
    SDL_IM_MODULE "fcitx"
    GTK_IM_MODULE "fcitx"
}'
        log "niri 配置追加：environment 输入法变量"
    fi

    # 关闭 niri 热角（与 DMS 顶栏/概览冲突）
    if ! grep -q '^[[:space:]]*gestures[[:space:]]*{' "$NIRI_CONFIG"; then
        append_to_niri 'gestures {
    hot-corners {
        off
    }
}'
        log "niri 配置追加：关闭热角"
    fi

    # Spotify 去白边
    if ! grep -q 'app-id="spotify"' "$NIRI_CONFIG"; then
        append_to_niri 'window-rule {
    match app-id="spotify"
    clip-to-geometry true
}'
        log "niri 配置追加：Spotify 去白边"
    fi

    install_touchpad_helper

    # 校验配置，失败只警告，不中断安装
    if command -v niri >/dev/null 2>&1; then
        if niri validate -c "$NIRI_CONFIG"; then
            log "niri 配置校验通过"
        else
            warn "niri 配置校验失败，请检查 $NIRI_CONFIG"
        fi
    fi
}

# 触摸板开关（Fn+F8）：沿用当前机器的实现，改 include 文件热重载
install_touchpad_helper() {
    local helper="$HOME/.local/bin/toggle-touchpad.sh"
    local state="$NIRI_DIR/touchpad-state.kdl"

    mkdir -p "$HOME/.local/bin"

    if [[ ! -f "$helper" ]]; then
        log "安装触摸板开关脚本：$helper"
        cat > "$helper" <<'SCRIPT'
#!/bin/sh
# Fn+F8 触摸板开关
# 原理：改写 niri 的 include 文件，niri 检测到变化后自动重载
# 优点：不需要 root，不依赖 /dev/input/eventN 编号
set -eu

STATE_FILE="$HOME/.config/niri/touchpad-state.kdl"

if grep -qE '^[[:space:]]*off[[:space:]]*$' "$STATE_FILE" 2>/dev/null; then
    cat > "$STATE_FILE" <<'EOF'
// ! 由 toggle-touchpad.sh 自动生成，请勿手动编辑 !
// 触摸板：已启用
EOF
    msg="已启用"
else
    cat > "$STATE_FILE" <<'EOF'
// ! 由 toggle-touchpad.sh 自动生成，请勿手动编辑 !
// 触摸板：已禁用
input {
    touchpad {
        off
    }
}
EOF
    msg="已禁用"
fi

# 兜底：万一 niri 没自动重载，显式触发一次
niri msg action load-config-file >/dev/null 2>&1 || true

command -v notify-send >/dev/null 2>&1 && notify-send -t 1200 "触摸板" "$msg" || true
SCRIPT
        chmod +x "$helper"
    fi

    if [[ ! -f "$state" ]]; then
        printf '// ! 由 toggle-touchpad.sh 自动生成，请勿手动编辑 !\n// 触摸板：已启用\n' > "$state"
    fi

    ensure_niri_include touchpad-state.kdl
}

configure_desktop() {
    log "把 dms 绑定到 niri 会话"
    systemctl --user daemon-reload
    if systemctl --user list-unit-files dms.service >/dev/null 2>&1 \
        && systemctl --user list-unit-files dms.service | grep -q '^dms\.service'; then
        systemctl --user add-wants niri.service dms
    else
        warn "未找到 dms.service，跳过。安装 dms-shell-niri 后重新运行本步骤即可。"
    fi
}

print_next_steps() {
    cat <<'EOF'

安装完成，接下来需要手动做的几件事：

  1. 如果不用显示管理器，在 TTY 里启动：
       niri-session
  2. 首次进入 niri 后检查：
       - fcitx5 是否已随桌面启动，拼音是否可用（fcitx5-configtool 可调整）
       - 截图快捷键 Print / Ctrl+Print / Alt+Print 是否正常
  3. 如果 niri 默认配置另外启动了 waybar，会和 DMS 顶栏重复：
       pkill waybar   # 并删除 config.kdl 里的 spawn-at-startup "waybar"
  4. 壁纸 / 主题 / 插件在 DMS 设置里调整：
       dms ipc call settings toggle

EOF
}

main() {
    check_environment

    ensure_multilib

    log "同步软件包数据库并升级系统 ..."
    sudo pacman -Syu --noconfirm

    classify_packages
    install_packages

    configure_system
    configure_input_method

    deploy_niri_config
    configure_niri_extras
    configure_desktop

    print_next_steps
}

main "$@"
