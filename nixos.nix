# Import this module from a NixOS host configuration. Home Manager must also be
# imported to apply the per-user niri and fcitx5 setup below.
{ lib, pkgs, ... }:

let
  resolvePackage = candidates:
    lib.findFirst (package: package != null) null
      (map (candidate: lib.attrByPath candidate null pkgs) candidates);

  packageSpecs = [
    { name = "xwayland-satellite"; candidates = [ [ "xwayland-satellite" ] ]; }
    { name = "xdg-desktop-portal-gnome"; candidates = [ [ "xdg-desktop-portal-gnome" ] ]; }
    { name = "xdg-desktop-portal-gtk"; candidates = [ [ "xdg-desktop-portal-gtk" ] ]; }
    { name = "DankMaterialShell"; candidates = [ [ "dankMaterialShell" ] [ "dms-shell" ] [ "dms-shell-niri" ] ]; }
    { name = "quickshell"; candidates = [ [ "quickshell" ] ]; }
    { name = "matugen"; candidates = [ [ "matugen" ] ]; }
    { name = "cava"; candidates = [ [ "cava" ] ]; }
    { name = "Qt 6 multimedia"; candidates = [ [ "qt6Packages" "qt6Multimedia" ] ]; }

    { name = "NetworkManager applet"; candidates = [ [ "nm-connection-editor" ] [ "networkmanagerapplet" ] ]; }
    { name = "Firefox"; candidates = [ [ "firefox" ] ]; }
    { name = "Git"; candidates = [ [ "git" ] ]; }
    { name = "Visual Studio Code"; candidates = [ [ "vscode" ] ]; }
    { name = "OnlyOffice"; candidates = [ [ "onlyoffice-bin" ] [ "onlyoffice" ] ]; }
    { name = "WeChat"; candidates = [ [ "wechat-uos" ] [ "wechat" ] ]; }
    { name = "QQ"; candidates = [ [ "qq" ] [ "linuxqq" ] ]; }
    { name = "Ghostty"; candidates = [ [ "ghostty" ] ]; }
    { name = "Alacritty"; candidates = [ [ "alacritty" ] ]; }
    { name = "Fish"; candidates = [ [ "fish" ] ]; }
    { name = "xdg-terminal-exec"; candidates = [ [ "xdg-terminal-exec" ] ]; }
    { name = "xdg-user-dirs"; candidates = [ [ "xdg-user-dirs" ] ]; }
    { name = "xdg-user-dirs-gtk"; candidates = [ [ "xdg-user-dirs-gtk" ] ]; }

    { name = "GNOME Control Center"; candidates = [ [ "gnome-control-center" ] ]; }
    { name = "Fuzzel"; candidates = [ [ "fuzzel" ] ]; }
    { name = "Swaylock"; candidates = [ [ "swaylock" ] ]; }
    { name = "GNOME polkit agent"; candidates = [ [ "polkit_gnome" ] ]; }
    { name = "GNOME Keyring"; candidates = [ [ "gnome-keyring" ] ]; }
    { name = "libsecret"; candidates = [ [ "libsecret" ] ]; }

    { name = "grim"; candidates = [ [ "grim" ] ]; }
    { name = "slurp"; candidates = [ [ "slurp" ] ]; }
    { name = "satty"; candidates = [ [ "satty" ] ]; }
    { name = "wl-clipboard"; candidates = [ [ "wl-clipboard" ] ]; }
    { name = "cliphist"; candidates = [ [ "cliphist" ] ]; }

    { name = "fcitx5"; candidates = [ [ "fcitx5" ] ]; }
    { name = "fcitx5 Chinese addons"; candidates = [ [ "fcitx5-chinese-addons" ] ]; }
    { name = "fcitx5 GTK"; candidates = [ [ "fcitx5-gtk" ] ]; }
    { name = "fcitx5 Qt"; candidates = [ [ "fcitx5-qt" ] ]; }
    { name = "fcitx5 configuration tool"; candidates = [ [ "fcitx5-configtool" ] ]; }

    { name = "pavucontrol"; candidates = [ [ "pavucontrol" ] ]; }
    { name = "playerctl"; candidates = [ [ "playerctl" ] ]; }
    { name = "GStreamer PipeWire plugin"; candidates = [ [ "gst_all_1" "gst-plugin-pipewire" ] ]; }
    { name = "GStreamer libav plugin"; candidates = [ [ "gst_all_1" "gst-libav" ] ]; }
    { name = "GStreamer good plugins"; candidates = [ [ "gst_all_1" "gst-plugins-good" ] ]; }
    { name = "Blueman"; candidates = [ [ "blueman" ] ]; }
    { name = "brightnessctl"; candidates = [ [ "brightnessctl" ] ]; }

    { name = "Nautilus"; candidates = [ [ "nautilus" ] ]; }
    { name = "File Roller"; candidates = [ [ "file-roller" ] ]; }
    { name = "7-Zip"; candidates = [ [ "_7zz" ] [ "p7zip" ] ]; }
    { name = "unzip"; candidates = [ [ "unzip" ] ]; }
    { name = "unrar"; candidates = [ [ "unrar" ] ]; }
    { name = "GVfs"; candidates = [ [ "gvfs" ] ]; }
    { name = "udisks2"; candidates = [ [ "udisks" ] ]; }
    { name = "GNOME Disks"; candidates = [ [ "gnome-disk-utility" ] ]; }

    { name = "fd"; candidates = [ [ "fd" ] ]; }
    { name = "ripgrep"; candidates = [ [ "ripgrep" ] ]; }
    { name = "fzf"; candidates = [ [ "fzf" ] ]; }
    { name = "zoxide"; candidates = [ [ "zoxide" ] ]; }
    { name = "bat"; candidates = [ [ "bat" ] ]; }
    { name = "eza"; candidates = [ [ "eza" ] ]; }
    { name = "btop"; candidates = [ [ "btop" ] ]; }
    { name = "fastfetch"; candidates = [ [ "fastfetch" ] ]; }
    { name = "starship"; candidates = [ [ "starship" ] ]; }
    { name = "jq"; candidates = [ [ "jq" ] ]; }

    { name = "mpv"; candidates = [ [ "mpv" ] ]; }
    { name = "imv"; candidates = [ [ "imv" ] ]; }
  ];
  fontSpecs = [
    { name = "Noto fonts"; candidates = [ [ "noto-fonts" ] ]; }
    { name = "Noto CJK fonts"; candidates = [ [ "noto-fonts-cjk-sans" ] [ "noto-fonts-cjk" ] ]; }
    { name = "Noto emoji fonts"; candidates = [ [ "noto-fonts-emoji" ] ]; }
    { name = "JetBrains Mono Nerd Font"; candidates = [ [ "nerd-fonts" "jetbrains-mono" ] ]; }
  ];

  resolvedPackages = map
    (spec: spec // { package = resolvePackage spec.candidates; })
    packageSpecs;
  resolvedFonts = map
    (spec: spec // { package = resolvePackage spec.candidates; })
    fontSpecs;
  availablePackages = map (spec: spec.package)
    (builtins.filter (spec: spec.package != null) resolvedPackages);
  missingPackages = builtins.filter (spec: spec.package == null) resolvedPackages;
  availableFonts = map (spec: spec.package)
    (builtins.filter (spec: spec.package != null) resolvedFonts);
  missingFonts = builtins.filter (spec: spec.package == null) resolvedFonts;
  inputMethodAddons = map resolvePackage [
    [ "fcitx5-chinese-addons" ]
    [ "fcitx5-gtk" ]
    [ "fcitx5-qt" ]
  ];

  touchpadToggle = pkgs.writeShellScriptBin "toggle-touchpad" ''
    set -eu
    state_file="$HOME/.config/niri/touchpad-state.kdl"
    mkdir -p "$HOME/.config/niri"

    if grep -qE '^[[:space:]]*off[[:space:]]*$' "$state_file" 2>/dev/null; then
      cat > "$state_file" <<'EOF'
    // ! Generated by toggle-touchpad; do not edit !
    // Touchpad: enabled
    EOF
      message="Touchpad enabled"
    else
      cat > "$state_file" <<'EOF'
    // ! Generated by toggle-touchpad; do not edit !
    // Touchpad: disabled
    input {
        touchpad {
            off
        }
    }
    EOF
      message="Touchpad disabled"
    fi

    niri msg action load-config-file >/dev/null 2>&1 || true
    if command -v notify-send >/dev/null 2>&1; then
      notify-send -t 1200 "Touchpad" "$message"
    fi
  '';

  niriHomeSetup = pkgs.writeShellScript "configure-niri-home" ''
    set -eu
    niri_dir="$HOME/.config/niri"
    niri_config="$niri_dir/config.kdl"
    backup_done=0
    mkdir -p "$niri_dir"

    if [ -L "$niri_config" ]; then
      echo "Warning: $niri_config is managed as a symlink; skipping automatic niri edits." >&2
      exit 0
    fi

    if [ ! -f "$niri_config" ]; then
      if command -v dms >/dev/null 2>&1; then
        if ! dms setup headless --compositor niri --terminal ghostty; then
          echo "Warning: DMS setup failed; creating a basic niri config." >&2
        fi
      fi
      if [ ! -f "$niri_config" ]; then
        : > "$niri_config"
      fi
    fi
    if [ ! -f "$niri_dir/touchpad-state.kdl" ]; then
      printf '%s\n' \
        '// Generated by toggle-touchpad; do not edit !' \
        '// Touchpad: enabled' > "$niri_dir/touchpad-state.kdl"
    fi

    backup_config() {
      if [ "$backup_done" -eq 0 ] && [ -f "$niri_config" ]; then
        cp -a "$niri_config" "$niri_config.bak-$(date +%Y%m%d-%H%M%S)"
        backup_done=1
      fi
    }
    append_config() {
      backup_config
      printf '\n%s\n' "$1" >> "$niri_config"
    }
    ensure_line() {
      if ! grep -Fq -- "$1" "$niri_config"; then
        append_config "$2"
      fi
    }
    ensure_include() {
      if [ -f "$niri_dir/$1" ]; then
        ensure_line "include \"$1\"" "include \"$1\""
      fi
    }

    for include in \
      dms/windowrules.kdl dms/cursor.kdl dms/layout.kdl \
      dms/outputs.kdl dms/input.kdl dms/binds.kdl touchpad-state.kdl; do
      ensure_include "$include"
    done

    ensure_line 'spawn-at-startup "fcitx5" "-d"' \
      'spawn-at-startup "fcitx5" "-d"'
    ensure_line 'polkit-gnome-authentication-agent-1' \
      'spawn-at-startup "polkit-gnome-authentication-agent-1"'

    if ! grep -q '^[[:space:]]*environment[[:space:]]*{' "$niri_config"; then
      append_config 'environment {
        XMODIFIERS "@im=fcitx"
        QT_IM_MODULE "fcitx"
        SDL_IM_MODULE "fcitx"
        GTK_IM_MODULE "fcitx"
    }'
    fi

    if ! grep -q '^[[:space:]]*gestures[[:space:]]*{' "$niri_config"; then
      append_config 'gestures {
        hot-corners {
            off
        }
    }'
    fi

    if ! grep -q 'app-id="spotify"' "$niri_config"; then
      append_config 'window-rule {
        match app-id="spotify"
        clip-to-geometry true
    }'
    fi

    if [ ! -f "$HOME/.config/fcitx5/profile" ]; then
      mkdir -p "$HOME/.config/fcitx5"
      cat > "$HOME/.config/fcitx5/profile" <<'EOF'
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=pinyin

    [Groups/0/Items/0]
    Name=keyboard-us

    [Groups/0/Items/1]
    Name=pinyin

    [GroupOrder]
    0=Default
    EOF
    fi

    if command -v niri >/dev/null 2>&1 && ! niri validate -c "$niri_config"; then
      echo "Warning: niri config validation failed: $niri_config" >&2
    fi
  '';
in
{
  nixpkgs.config.allowUnfreePredicate = package:
    builtins.elem (lib.getName package) [
      "vscode"
      "onlyoffice-bin"
      "onlyoffice"
      "wechat-uos"
      "wechat"
      "qq"
      "linuxqq"
      "steam"
      "steam-unwrapped"
      "unrar"
    ];

  programs.niri.enable = true;
  programs.fish.enable = true;
  programs.steam.enable = true;
  users.defaultUserShell = pkgs.fish;

  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;
  security.polkit.enable = true;

  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = builtins.filter (package: package != null) inputMethodAddons;
  };

  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  environment.systemPackages = availablePackages;
  fonts.packages = availableFonts;

  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.packages = [ touchpadToggle ];
      home.sessionVariables = {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "ibus";
      };
      xdg.userDirs.enable = true;
      xdg.userDirs.createDirectories = true;
      home.activation.configureNiri = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${niriHomeSetup}
      '';
    })
  ];

  warnings = map
    (spec: "nixos.nix: package '${spec.name}' was not found in pkgs and will be skipped.")
    (missingPackages ++ missingFonts);
}
