#!/bin/env zsh

[[ "$TTY" == /dev/tty* ]] || return 0

# Export environment from systemd user configuration:
export $(systemctl --user show-environment)

# Set the gnuPG tty for the gpg agent:
export GPG_TTY=$(tty)

# Set SSH agent socket (as it was started by systemd):
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"

# Update the gpg agent:
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

# Update systemd environment:
systemctl --user import-environment GPG_TTY SSH_AUTH_SOCK

# Start sway:
if [[ -z "$DISPLAY" && "$(tty)" = "/dev/tty1" ]]; then
  	# Run sway attached to systemd
	systemd-cat -t "sway" sway
	systemctl --user stop graphical-session.target
	systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
fi

