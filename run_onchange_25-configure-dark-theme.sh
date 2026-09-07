#!/usr/bin/env bash
# Prefer dark theme system-wide via gsettings/dconf. This is what
# GTK4/libadwaita apps and the xdg-desktop-portal "appearance" signal
# (color-scheme) read - e.g. it's what Zen Browser's "Automatic" website
# appearance follows. There's no session settings daemon in this openbox
# setup to set it interactively, so it defaults to light otherwise.
#
# Older GTK3 apps (especially libxfce4ui ones like Thunar) don't honor
# this at all - see dot_config/private_openbox/environment for that half.
set -euo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not found; skipping dark theme setup" >&2
  exit 0
fi

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
