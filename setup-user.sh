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
    echo "systemctl --user enable --now "$1""
    systemctl --user enable --now "$1"
}

echo "==========================="
echo "Setting up user dotfiles..."
echo "==========================="

link ".gnupg/gpg.conf"
link ".gnupg/gpg-agent.conf"

link ".magic"

link ".config/environment.d"

link ".config/zsh/.zprofile"
link ".config/zsh/.zsh-aliases"
link ".config/zsh/.zshenv"
link ".config/zsh/.zshrc"
link ".config/zsh/.p10k.zsh"

link ".config/git"

link ".config/sway/config"
link ".config/sway/config.d"

link ".config/bat"

link ".local/bin"
link ".local/share/applications"

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping user services..."
else
    echo ""
    echo "================================="
    echo "Enabling and starting services..."
    echo "================================="

    systemctl --user daemon-reload
fi

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

echo "Configuring MIME types"
file --compile --magic-file "$HOME/.magic"

find "$HOME/.gnupg" -type f -not -path "*#*" -exec chmod 600 {} \;
find "$HOME/.gnupg" -type d -exec chmod 700 {} \;

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
