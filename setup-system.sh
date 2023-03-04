#!/bin/env bash
#
# Description:  Sync system (/etc) dotfiles
# Usage:        Run in regular mode to update system from dotfiles. 
#               Run with "-r" switch to update dotfiles from system.
# Author:       Pavle Batuta <pavle@batuta.xyz>
# Credits:      maximbaz

set -e
exec 2> >(while read line; do echo -e "\e[01;31m$line\e[0m"; done)

# Set script vars:
script_name="$(basename "$0")"
dotfiles_dir="$(
    cd "$(dirname "$0")"
    pwd
)"
cd "$dotfiles_dir"

# Sudo prompt
if (("$EUID")); then
    sudo -s "$dotfiles_dir/$script_name" "$@"
    exit 0
fi

if [ "$1" = "-r" ]; then
    echo >&2 "Running in reverse mode!"
    reverse=1
fi

# Copies a file from source to destination.
# If reverse mode is set, the file is copied from destination to source.
# Args:
#   $1 - path to file to copy
#   $2 (optional) - flags to set on the file
#   $3 (optonal) - name of the destination file
copy() {
    if [ -z "$reverse" ]; then
        orig_file="$dotfiles_dir/$1"
        [ -n "$3" ] && dest_file="/$3" || dest_file="/$1"
    else
        [ -n "$3" ] && orig_file="/$3" || orig_file="/$1"
        dest_file="$dotfiles_dir/$1"
    fi

    mkdir -p "$(dirname "$orig_file")"
    mkdir -p "$(dirname "$dest_file")"

    rm -rf "$dest_file"

    cp -R "$orig_file" "$dest_file"
    if [ -z "$reverse" ]; then
        [ -n "$2" ] && chmod "$2" "$dest_file"
    else
        chown -R pax "$dest_file"
    fi
    echo "$dest_file <= $orig_file"
}

is_chroot() {
    ! cmp -s /proc/1/mountinfo /proc/self/mountinfo
}

systemctl_enable() {
    echo "systemctl enable $1"
    systemctl enable "$1"
}

systemctl_enable_start() {
    echo "systemctl enable --now $1"
    systemctl enable "$1"
    systemctl start "$1"
}

echo ""
echo "============================"
echo "Setting up /usr/local/bin..."
echo "============================"

echo "Nothing to set up, skipping..."

echo ""
echo "=========================="
echo "Setting up /etc configs..."
echo "=========================="

copy "etc/mkinitcpio.conf"
copy "etc/bluetooth/main.conf"
copy "etc/conf.d/snapper"
copy "etc/default/earlyoom"
copy "etc/docker/daemon.json"
copy "etc/fwupd/uefi_capsule.conf"
copy "etc/iwd/main.conf"
copy "etc/pacman.conf" 644
copy "etc/pacman.d/hooks"
copy "etc/pam.d/polkit-1"
copy "etc/snap-pac.ini"
copy "etc/snapper/configs/root"
copy "etc/ssh/ssh_config"
copy "etc/sudoers.d/override"
copy "etc/sysctl.d/99-sysctl.conf"
copy "etc/systemd/journald.conf.d/override.conf"
copy "etc/systemd/logind.conf.d/override.conf"
copy "etc/systemd/network/20-wireless.network"
copy "etc/systemd/network/50-wired.network"
copy "etc/systemd/resolved.conf.d/dnssec.conf"
copy "etc/systemd/system/getty@tty1.service.d/override.conf"
copy "etc/systemd/system/usbguard.service.d/override.conf"
copy "etc/systemd/system/system-dotfiles-sync.service"
copy "etc/systemd/system/system-dotfiles-sync.timer"
copy "etc/systemd/system.conf.d/kill-fast.conf"
copy "etc/usbguard/usbguard-daemon.conf" 600
copy "etc/zsh/zshenv"

(("$reverse")) && exit 0

echo ""
echo "================================="
echo "Enabling and starting services..."
echo "================================="

sysctl --system > /dev/null

systemctl daemon-reload
systemctl_enable_start "bluetooth.service"
# systemctl_enable_start "btrfs-scrub@-.timer"
systemctl_enable_start "docker.socket"
systemctl_enable_start "earlyoom.service"
systemctl_enable_start "fstrim.timer"
systemctl_enable_start "iwd.service"
systemctl_enable_start "linux-modules-cleanup.service"
# systemctl_enable_start "lenovo_fix.service"
systemctl_enable_start "pcscd.socket"
systemctl_enable_start "reflector.timer"
systemctl_enable_start "snapper-cleanup.timer"
systemctl_enable_start "system-dotfiles-sync.timer"
systemctl_enable_start "systemd-networkd.socket"
systemctl_enable_start "systemd-resolved.service"
systemctl_enable_start "tlp.service"

if [ ! -s "/etc/usbguard/rules.conf" ]; then
    echo >&2 "=== Remember to set usbguard rules: usbguard generate-policy >! /etc/usbguard/rules.conf"
else
    chmod 600 /etc/usbguard/rules.conf
    systemctl_enable_start "usbguard.service"
    systemctl_enable_start "usbguard-dbus.service"
fi

echo ""
echo "==============================="
echo "Creating top level Trash dir..."
echo "==============================="
mkdir --parent /.Trash
chmod a+rw /.Trash
chmod +t /.Trash
echo "Done"

echo ""
echo "======================================="
echo "Finishing various user configuration..."
echo "======================================="

if is_chroot; then
    echo >&2 "=== Running in chroot, skipping /etc/resolv.conf setup..."
else
    echo "Configuring /etc/resolv.conf"
    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

echo "Configuring NTP"
timedatectl set-ntp true

echo "Configuring aurutils"
mkdir -p /etc/aurutils
ln -sf /etc/pacman.conf "/etc/aurutils/pacman-pax-local.conf"
ln -sf /etc/pacman.conf "/etc/aurutils/pacman-$(uname -m).conf"
