#!/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG="install.log"

echo ":: Starting installtion from $DOTFILES_DIR..."
echo ":: Installing core packages..."

sudo pacman -S --noconfirm --needed \
    sway swaybg swaylock swayidle \
    waybar alacritty networkmanager \
    ufw pulsemixer brightnessctl \
    base-devel git meson udiskie \
    wayland-protocols wlsunset ly \
    ttf-hack-nerd ttf-agave-nerd \
    mako wl-clipboard \
    freetype2 harfbuzz cairo pango \
	wayland libxkbcommon scdoc jq

echo ":: Building and installing tofi..."

if ! command -v tofi &> /dev/null; then
    echo ":: Building and installing tofi..."
    cd /tmp
    rm -rf tofi
    git clone https://github.com/philj56/tofi.git
    cd tofi
    meson build
    sudo ninja -C build install
    echo ":: Tofi installed."
else
    echo ":: Tofi is already installed. Skipping."
fi

mkdir -p ~/.config
mkdir -p ~/.config/sway
mkdir -p ~/.config/waybar
mkdir -p ~/.config/tofi
mkdir -p ~/.config/mako

link_config() {
	SOURCE="$DOTFILES_DIR/$1"
	TARGET="$HOME/.config/$2"

	if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
		echo "   Backing up existing $TARGET to $TARGET.bak"
		mv "$TARGET" "$TARGET.bak"
	fi

	echo "   Linking $1 -> $2"
	rm -rf "$TARGET"
	ln -s "$SOURCE" "$TARGET"
}

echo ":: Linking dotfiles..."

link_config "sway" "sway"
link_config "tofi" "tofi"
link_config "mako" "mako"
chmod +x "$DOTFILES_DIR/scripts/"*

echo ":: Configuring Waybar..."

rm -rf ~/.config/waybar/style.css
ln -s "$DOTFILES_DIR/waybar/style.css" ~/.config/waybar/style.css

cp "$DOTFILES_DIR/waybar/config.jsonc" ~/.config/waybar/config.jsonc

if ! ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
    echo "   Desktop detected (No Battery). Removing modules..."
    
    TMP_CONFIG=$(mktemp)
    jq 'del(.["modules-right"][] | select(. == "custom/battery" or . == "backlight"))' \
        ~/.config/waybar/config.jsonc > "$TMP_CONFIG" && mv "$TMP_CONFIG" ~/.config/waybar/config.jsonc
    
    echo "   Waybar config optimized for Desktop."
else
    echo "   Laptop detected. Keeping Battery modules."
fi

echo ":: Setting up scripts..."

mkdir -p ~/.config/sway/scripts
cp "$DOTFILES_DIR/scripts/"* ~/.config/sway/scripts/
chmod +x ~/.config/sway/scripts/*

echo ":: Enabling services..."

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now ufw

if systemctl is-active --quiet getty@tty2.service; then
    echo "   Stopping getty@tty2 to free up the display..."
    sudo systemctl stop getty@tty2.service
fi
sudo systemctl disable getty@tty2.service
sudo systemctl enable ly@tty2.service

sudo ufw default deny incoming
sudo ufw default allow outgoing
# sudo ufw allow ssh
sudo ufw enable

echo ":: Installation completed"
