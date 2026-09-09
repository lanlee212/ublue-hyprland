#!/usr/bin/env bash
# ublue-hyprland: first-login config installer (no-clobber, idempotent).
# Ships the minimal Hyprland config that autostarts the Noctalia shell.
# Pattern matches the old ublue-qtile profile.d copy.

SRC=/usr/share/ublue-hyprland/config

# --- Hyprland config (only if the user has none yet) ---
if [ -d "$SRC/hypr" ] && [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua" ]; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    cp -n "$SRC/hypr/hyprland.lua" "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
fi

# Noctalia intentionally NOT shipped: it generates its own config
# (setup wizard) on first launch.
