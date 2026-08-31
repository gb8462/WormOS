#!/bin/bash

# ============================================================
# WormOS - Desktop Setup
#
# Installs and configures a lightweight Hyprland desktop
# environment on Arch Linux.
# ============================================================

set -Eeuo pipefail

trap 'echo; echo "ERROR: Setup failed on line $LINENO."; exit 1' ERR

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

cd "$HOME"

CONFIG_DIR="$HOME/WormOS"

HYPR_DIR="$HOME/.config/hypr"
CONFIG_HOME="$HOME/.config"

# WormOS wallpaper directory
WALLPAPER_DIR="/usr/share/wallpaper"

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

info() {
    echo
    echo "==> $1"
}

warn() {
    echo "WARNING: $1"
}

error() {
    echo "ERROR: $1"
}

# ------------------------------------------------------------
# Check repository
# ------------------------------------------------------------

info "Checking WormOS repository..."

if [[ ! -d "$CONFIG_DIR" ]]; then
    error "$CONFIG_DIR not found."
    echo "Please clone the WormOS repository first."
    exit 1
fi

echo "WormOS repository found:"
echo "  $CONFIG_DIR"

# ------------------------------------------------------------
# Check required configuration files
# ------------------------------------------------------------

info "Checking WormOS configuration files..."

REQUIRED_FILES=(
    "$CONFIG_DIR/configs/hypr/hyprland.lua"
    "$CONFIG_DIR/configs/hypr/hyprpaper.conf"
    "$CONFIG_DIR/configs/wofi"
    "$CONFIG_DIR/configs/alacritty.toml"
    "$CONFIG_DIR/configs/waybar"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -e "$file" ]]; then
        warn "Missing configuration: $file"
    fi
done

# ------------------------------------------------------------
# Update system
# ------------------------------------------------------------

info "Updating system..."

if ! sudo pacman -Syu --needed --noconfirm; then
    error "System update failed."
    exit 1
fi

# ------------------------------------------------------------
# Install official repository packages
# ------------------------------------------------------------

info "Installing desktop packages..."

PACKAGES=(

    # --------------------------------------------------------
    # Desktop / compositor
    # --------------------------------------------------------

    "hyprland"
    "hyprpaper"
    "waybar"
    "wofi"

    # --------------------------------------------------------
    # Applications
    # --------------------------------------------------------

    "dolphin"
    "firefox"
    "alacritty"
    "vim"

    # --------------------------------------------------------
    # Audio
    # --------------------------------------------------------

    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "pavucontrol"

    # --------------------------------------------------------
    # Wayland utilities
    # --------------------------------------------------------

    "xdg-desktop-portal-hyprland"
    "grim"
    "slurp"
    "wl-clipboard"

    # --------------------------------------------------------
    # Hardware / media controls
    # --------------------------------------------------------

    "brightnessctl"
    "playerctl"

    # --------------------------------------------------------
    # General utilities
    # --------------------------------------------------------

    "git"
    "unzip"
    "man"

    # --------------------------------------------------------
    # Fonts
    # --------------------------------------------------------

    "noto-fonts"
    "nerd-fonts"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "ttf-font-awesome"
)

sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Desktop packages installed successfully."

# ------------------------------------------------------------
# Install yay
# ------------------------------------------------------------

info "Checking yay..."

if command -v yay >/dev/null 2>&1; then

    echo "yay is already installed."

else

    echo "Installing yay..."

    YAY_DIR="$(mktemp -d)"

    cleanup_yay() {
        rm -rf "$YAY_DIR"
    }

    trap 'cleanup_yay' EXIT

    git clone https://aur.archlinux.org/yay.git "$YAY_DIR/yay"

    (
        cd "$YAY_DIR/yay"
        makepkg -si --noconfirm
    )

    cleanup_yay

    trap 'echo; echo "ERROR: Setup failed on line $LINENO."; exit 1' ERR

    echo "yay installed successfully."

fi

# ------------------------------------------------------------
# Install AUR packages
# ------------------------------------------------------------

info "Installing AUR packages..."

AUR_PACKAGES=(
    "wlogout"
    "brave-bin"
)

for package in "${AUR_PACKAGES[@]}"; do

    if yay -Q "$package" >/dev/null 2>&1; then

        echo "$package is already installed."

    else

        echo "Installing $package..."

        yay -S --needed --noconfirm "$package"

    fi

done

# ------------------------------------------------------------
# Create configuration directories
# ------------------------------------------------------------

info "Creating configuration directories..."

mkdir -p "$CONFIG_HOME"
mkdir -p "$HYPR_DIR"

# ------------------------------------------------------------
# Install application configurations
# ------------------------------------------------------------

info "Installing application configurations..."

CONFIGS=(
    "wofi"
    "alacritty.toml"
    "waybar"
)

for config in "${CONFIGS[@]}"; do

    SOURCE="$CONFIG_DIR/configs/$config"
    DEST="$CONFIG_HOME/$config"

    if [[ ! -e "$SOURCE" ]]; then
        warn "Skipping missing configuration: $SOURCE"
        continue
    fi

    if [[ -e "$DEST" ]]; then

        echo "Existing configuration found:"
        echo "  $DEST"

        echo "Creating backup..."
        rm -rf "${DEST}.backup"
        cp -r "$DEST" "${DEST}.backup"

        echo "Backup created:"
        echo "  ${DEST}.backup"

        echo "Replacing configuration..."

        rm -rf "$DEST"
        cp -r "$SOURCE" "$DEST"

        echo "Installed: $config"

    else

        cp -r "$SOURCE" "$DEST"

        echo "Installed: $config"

    fi

done

# ------------------------------------------------------------
# Install Hyprland Lua configuration
# ------------------------------------------------------------

info "Installing Hyprland configuration..."

HYPR_LUA="$CONFIG_DIR/configs/hypr/hyprland.lua"
HYPR_DEST="$HYPR_DIR/hyprland.lua"

if [[ -f "$HYPR_LUA" ]]; then

    if [[ -e "$HYPR_DEST" ]]; then

        echo "Existing hyprland.lua found."
        echo "Creating backup..."

        rm -f "${HYPR_DEST}.backup"
        cp "$HYPR_DEST" "${HYPR_DEST}.backup"

        echo "Backup created:"
        echo "  ${HYPR_DEST}.backup"

    fi

    cp "$HYPR_LUA" "$HYPR_DEST"

    echo "Installed hyprland.lua."

else

    warn "hyprland.lua not found."
    echo "Expected:"
    echo "  $HYPR_LUA"

fi

# ------------------------------------------------------------
# Install Hyprpaper configuration
# ------------------------------------------------------------

info "Installing Hyprpaper configuration..."

HYPRPAPER_CONFIG="$CONFIG_DIR/configs/hypr/hyprpaper.conf"
HYPRPAPER_DEST="$HYPR_DIR/hyprpaper.conf"

if [[ -f "$HYPRPAPER_CONFIG" ]]; then

    if [[ -e "$HYPRPAPER_DEST" ]]; then

        echo "Existing hyprpaper.conf found."
        echo "Creating backup..."

        rm -f "${HYPRPAPER_DEST}.backup"
        cp "$HYPRPAPER_DEST" "${HYPRPAPER_DEST}.backup"

        echo "Backup created:"
        echo "  ${HYPRPAPER_DEST}.backup"

    fi

    cp "$HYPRPAPER_CONFIG" "$HYPRPAPER_DEST"

    echo "Installed hyprpaper.conf."

else

    warn "hyprpaper.conf not found."

fi

# ------------------------------------------------------------
# Install wallpapers
# ------------------------------------------------------------

info "Installing wallpapers..."

WALLPAPER_SOURCE="$CONFIG_DIR/Wallpapers"

if [[ -d "$WALLPAPER_SOURCE" ]]; then

    sudo mkdir -p "$WALLPAPER_DIR"

    shopt -s nullglob

    WALLPAPERS=(
        "$WALLPAPER_SOURCE"/*
    )

    if (( ${#WALLPAPERS[@]} == 0 )); then

        warn "No wallpapers found in $WALLPAPER_SOURCE."

    else

        for wallpaper in "${WALLPAPERS[@]}"; do

            filename="$(basename "$wallpaper")"

            if [[ -e "$WALLPAPER_DIR/$filename" ]]; then

                echo "Wallpaper already exists: $filename"

            else

                sudo cp -r "$wallpaper" "$WALLPAPER_DIR/"
                echo "Installed wallpaper: $filename"

            fi

        done

    fi

    shopt -u nullglob

else

    warn "Wallpaper directory not found:"
    echo "  $WALLPAPER_SOURCE"

fi

# ------------------------------------------------------------
# Vim configuration
# ------------------------------------------------------------

info "Configuring Vim..."

VIM_CONFIG="$CONFIG_DIR/configs/.vimrc"
VIM_DEST="$HOME/.vimrc"

if [[ -f "$VIM_CONFIG" ]]; then

    if [[ -e "$VIM_DEST" ]]; then

        echo "Existing .vimrc found."
        echo "Creating backup..."

        rm -f "${VIM_DEST}.backup"
        cp "$VIM_DEST" "${VIM_DEST}.backup"

        echo "Backup created:"
        echo "  ${VIM_DEST}.backup"

    fi

    cp "$VIM_CONFIG" "$VIM_DEST"

    echo "Installed .vimrc."

else

    warn ".vimrc not found."

fi

# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

info "Verifying installation..."

COMMANDS=(
    "hyprland"
    "hyprpaper"
    "waybar"
    "wofi"
    "dolphin"
    "firefox"
    "alacritty"
    "wlogout"
    "brave"
    "brightnessctl"
    "playerctl"
)

for command in "${COMMANDS[@]}"; do

    if command -v "$command" >/dev/null 2>&1; then

        echo "[OK] $command"

    else

        warn "$command was not found in PATH."

    fi

done

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "============================================================"
echo "                  WormOS Setup Complete"
echo "============================================================"
echo
echo "Installed:"
echo "  - Hyprland"
echo "  - Hyprpaper"
echo "  - Waybar"
echo "  - Wofi"
echo "  - Wlogout"
echo "  - Brave"
echo "  - Dolphin"
echo "  - Firefox"
echo "  - Alacritty"
echo "  - Vim"
echo "  - PipeWire / WirePlumber"
echo "  - Wayland utilities"
echo "  - Brightness / media controls"
echo "  - Fonts"
echo
echo "Configured:"
echo "  - ~/.config/hypr/hyprland.lua"
echo "  - ~/.config/hypr/hyprpaper.conf"
echo "  - Waybar"
echo "  - Wofi"
echo "  - Alacritty"
echo "  - Vim"
echo
echo "Backups:"
echo "  - Existing configurations are saved as .backup"
echo
echo "Wallpapers:"
echo "  - $WALLPAPER_DIR"
echo
echo "============================================================"
echo

# ------------------------------------------------------------
# Reboot
# ------------------------------------------------------------

read -rp "Do you want to reboot now? (y/n): " REBOOT

if [[ "$REBOOT" =~ ^[Yy]$ ]]; then

    echo
    echo "Rebooting WormOS..."
    sleep 1
    reboot

else
    echo
    echo "Reboot skipped."
    echo "Please reboot manually when you're ready."

fi