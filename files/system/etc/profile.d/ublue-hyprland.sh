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

# --- Umbriel config (only if the user has none yet) ---
# Port of the Hyprland config for Noctalia's own compositor. Same no-clobber
# rule: an existing ~/.config/umbriel/config.toml (or later user edits) wins.
if [ -d "$SRC/umbriel" ] && [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/umbriel/config.toml" ]; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/umbriel"
    cp -n "$SRC/umbriel/config.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/umbriel/config.toml"
fi

# Session-bound helper scripts (Mod+L lock+suspend, the screenshot submap) are
# NOT copied: both configs bind them from /usr/share/ublue-hyprland/scripts/,
# which exists on every machine built from this image.

# Noctalia intentionally NOT shipped: it generates its own config
# (setup wizard) on first launch.
