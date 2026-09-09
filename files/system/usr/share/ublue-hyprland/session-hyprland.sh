#!/usr/bin/env bash
# Session wrapper for Hyprland on greetd-launched logins.
#
# greetd execs the session command directly (no display-manager shell), so
# /etc/profile is never sourced and profile.d first-login installers
# (ublue-hyprland.sh copies the shipped config on first login) would never
# run for fresh users. Source /etc/profile here, then hand off to the COPR's
# start-hyprland launcher.
if [ -r /etc/profile ]; then
    # shellcheck disable=SC1091
    . /etc/profile
fi
exec /usr/bin/start-hyprland "$@"
