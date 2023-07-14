#!/bin/env bash

set -e
exec 2> >(while read line; do echo -e "\e[01;31m$line\e[0m"; done)

dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

# Create a symlink between the master file in the dotfiles and the $XDG_CONFIG_DIR
# Args: $1 - source path, relative to dotfiles root
#       $2 (optional) - destination path, relative to $HOME
link() {
    orig_file="$dotfiles_dir/$1"
    if [ -n "$2" ]; then
        dest_file="$HOME/$2"
    else
        dest_file="$HOME/$1"
    fi
    
    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"
    
    rm -rf "$dest_file"
    ln -s "$orig_file" "$dest_file"
    echo "$dest_file -> $orig_file"
}

is_chroot() {
    ! cmp -s /proc/1/mountinfo /proc/self/mountinfo
}

systemctl_enable_start() {
    echo "systemctl --user enable --now $1"
    systemctl --user enable --now "$1"
}

echo "==========================="
echo "Setting up user dotfiles..."
echo "==========================="

link ".magic"

link ".config/environment.d"

link ".config/zsh/.zprofile"
link ".config/zsh/.zsh-aliases"
link ".config/zsh/.zshenv"
link ".config/zsh/.zshrc"
link ".config/zsh/.p10k.zsh"
link ".config/zsh/scripts"

link ".config/systemd/user/hyprland-session.target"
link ".config/systemd/user/battery-low-notify.service"
link ".config/systemd/user/polkit-gnome.service"
link ".config/systemd/user/systembus-notify.service"
link ".config/systemd/user/udiskie.service"

link ".config/git"

link ".config/hypr/hyprland.conf"

link ".config/bat"
link ".config/waybar"
link ".config/wldash"
link ".config/swaylock"
link ".config/kitty"
link ".config/swaync"
link ".config/tig"
link ".config/npm"
link ".config/mpv"
link ".config/swappy"
link ".config/xdg-desktop-portal-wlr"
link ".config/xdg-desktop-portal-hyprland"
link ".config/gtk-3.0"
link ".config/vimiv"

link ".config/discord-flags.conf"

link ".local/bin"
link ".local/share/applications"

link ".local/share/gnupg/gpg-agent.conf"
link ".local/share/gnupg/gpg.conf"

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping user services..."
else
    echo ""
    echo "================================="
    echo "Enabling and starting services..."
    echo "================================="
    
    systemctl --user daemon-reload
    
    systemctl_enable_start "swaync.service"
    systemctl_enable_start "battery-low-notify.service"
    systemctl_enable_start "polkit-gnome.service"
    systemctl_enable_start "systembus-notify.service"
    systemctl_enable_start "udiskie.service"
    systemctl_enable_start "yubikey-touch-detector.socket"
fi

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

echo "Configuring MIME types"
file --compile --magic-file "$HOME/.magic"

find "$HOME/.local/share/gnupg" -type f -not -path "*#*" -exec chmod 600 {} \;
find "$HOME/.local/share/gnupg" -type d -exec chmod 700 {} \;

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping YubiKey configuration..."
else
    if [ ! -s "$HOME/.config/Yubico/u2f_keys" ]; then
        echo "Configuring YubiKey for passwordless sudo (touch it now)"
        mkdir -p "$HOME/.config/Yubico"
        pamu2fcfg -upax > "$HOME/.config/Yubico/u2f_keys"
    fi
fi

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping GTK file chooser dialog configuration..."
else
    echo "Configuring GTK file chooser dialog"
    gsettings set org.gtk.Settings.FileChooser sort-directories-first true
fi

echo "Ignoring further changes to often changing config"
# TODO: add files that change often here

echo "Configure repo-local git settings"
git config user.email "pavle@batuta.xyz"
git remote set-url origin "git@github.com:paxthemax/dotfiles.git"
