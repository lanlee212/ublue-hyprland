#!/usr/bin/env bash
# ublue-hyprland: SUPER+L parity (qtile-era betterlockscreen behaviour).
# Pause every media player, then lock AND suspend through Noctalia: the lock
# screen shows first, resuming lands on the lock screen, and the player stays
# paused.
#
# Shipped system-wide instead of living in a user's ~/.config/hypr/scripts so
# both the Hyprland and the Umbriel session configs can bind one stable path
# that exists on any machine built from this image.
set -u

playerctl pause --all-players 2>/dev/null || true

if ! noctalia msg session lock-and-suspend 2>/dev/null; then
    # Noctalia unavailable: lock through logind first, so the suspend fallback
    # can never resume into an unlocked session.
    loginctl lock-session 2>/dev/null || true
    sleep 1
    systemctl suspend
fi
