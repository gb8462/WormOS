```bash
#!/bin/bash

# ============================================================
# WormOS - Desktop Setup
# Builds a lightweight Hyprland desktop environment on Arch.
# ============================================================

set -Eeuo pipefail
trap 'echo "Error occurred on line $LINENO"; exit 1' ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

cd "$HOME"

CONFIG_DIR="$HOME/Hyprland-Configs"

# ------------------------------------------------------------
# Check repository
# ------------------------------------------------------------

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Error: $CONFIG_DIR not found!"
    echo "Please clone the WormOS repository first."
    exit 1
fi

# ------------------------------------------------------------
# Update system
# ------------------------------------------------------------

echo "==> Updating system..."

if ! sudo pacman -Syu --needed --noconfirm; then
    echo "System update failed."
    exit 1
fi

# ------------------------------------------------------------
# Install desktop packages
# ------------------------------------------------------------

echo "==> Installing desktop packages..."

PACKAGES=(
    # Desktop
    "hyprland"
    "hyprpaper"
    "waybar"
    "wofi"
    "wlogout"

    # Applications
    "dolphin"
    "firefox"
    "alacritty"
    "vim"

    # Audio
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "pavucontrol"

    # Wayland utilities
    "xdg-desktop-portal-hyprland"
    "grim"
    "slurp"
    "wl-clipboard"

    # Hardware / media controls
    "brightnessctl"
    "playerctl"

    # General utilities
    "git"
    "unzip"
    "man"

    # Fonts
    "noto-fonts"
    "nerd-fonts"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "ttf-font-awesome"

    # Login manager
    "lightdm"
    "lightdm-slick-greeter"
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "==> Desktop packages installed."

# ------------------------------------------------------------
# Install yay
# ------------------------------------------------------------

echo "==> Checking yay..."

if ! command -v yay >/dev/null 2>&1; then
    echo "==> Installing yay..."

    YAY_DIR="$(mktemp -d)"

    git clone https://aur.archlinux.org/yay.git "$YAY_DIR/yay"

    (
        cd "$YAY_DIR/yay"
        makepkg -si --noconfirm
    )

    rm -rf "$YAY_DIR"

    echo "==> yay installed."
else
    echo "==> yay is already installed."
fi

# ------------------------------------------------------------
# Configure desktop applications
#
# NOTE:
# WormOS intentionally does NOT copy:
#   - hyprland.conf
#   - hyprpaper.conf
#   - Wallpapers
#
# These are left untouched so the user can configure them
# manually.
# ------------------------------------------------------------

echo "==> Configuring desktop applications..."

mkdir -p "$HOME/.config"

CONFIGS=(
    "wofi"
    "alacritty.toml"
    "waybar"
    "wlogout"
)

for config in "${CONFIGS[@]}"; do

    SOURCE="$CONFIG_DIR/configs/$config"
    DEST="$HOME/.config/$config"

    if [ ! -e "$SOURCE" ]; then
        echo "Warning: $SOURCE not found."
        continue
    fi

    if [ ! -e "$DEST" ]; then
        cp -r "$SOURCE" "$HOME/.config"
        echo "Installed configuration: $config"
    else
        echo "Configuration already exists: $config"
    fi

done

# ------------------------------------------------------------
# Vim configuration
# ------------------------------------------------------------

echo "==> Configuring Vim..."

VIM_CONFIG="$CONFIG_DIR/configs/.vimrc"

if [ -f "$VIM_CONFIG" ]; then

    if [ ! -e "$HOME/.vimrc" ]; then
        cp "$VIM_CONFIG" "$HOME/.vimrc"
        echo "Vim configuration installed."
    else
        echo "Vim configuration already exists."

    fi

else
    echo "Warning: $VIM_CONFIG not found."

fi

# ------------------------------------------------------------
# LightDM
# ------------------------------------------------------------

echo "==> Configuring LightDM..."

LIGHTDM_DIR="$CONFIG_DIR/configs/Lightdm"

if [ -d "$LIGHTDM_DIR" ]; then

    if [ -f "$LIGHTDM_DIR/slick-greeter.conf" ]; then
        sudo cp \
            "$LIGHTDM_DIR/slick-greeter.conf" \
            /etc/lightdm/slick-greeter.conf
    fi

    if [ -f "$LIGHTDM_DIR/lightdm.conf" ]; then
        sudo cp \
            "$LIGHTDM_DIR/lightdm.conf" \
            /etc/lightdm/lightdm.conf
    fi

else
    echo "Warning: LightDM configuration directory not found."
fi

sudo systemctl enable lightdm.service

echo "==> LightDM configured."

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------

echo
echo "============================================"
echo "             WormOS Setup Complete"
echo "============================================"
echo
echo "Installed:"
echo "  - Hyprland"
echo "  - Hyprpaper"
echo "  - Waybar"
echo "  - Wofi"
echo "  - Wlogout"
echo "  - Dolphin"
echo "  - Firefox"
echo "  - Alacritty"
echo "  - PipeWire"
echo "  - Wayland utilities"
echo "  - Fonts"
echo "  - LightDM"
echo
echo "WormOS intentionally did NOT modify:"
echo "  - ~/.config/hypr/hyprland.conf"
echo "  - ~/.config/hypr/hyprpaper.conf"
echo "  - /usr/share/wallpaper"
echo
echo "You can configure your Hyprland environment manually."
echo

read -rp "Do you want to reboot now? (y/n): " REBOOT

if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Reboot skipped."
    echo "Please reboot manually when you're ready."
fi
```
