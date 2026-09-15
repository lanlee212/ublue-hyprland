#!/usr/bin/env bash
# ublue-hyprland: grim/slurp screenshots (wlr-screencopy route, no portal).
#
#   screenshot.sh full       full output
#   screenshot.sh area       pick a region with slurp
#   screenshot.sh annotate   region -> satty (NOT installed in this image; the
#                            shipped Umbriel/Hyprland configs use Noctalia's own
#                            `noctalia msg screenshot-annotate` for that instead)
#
# The shipped configs prefer Noctalia's `noctalia msg screenshot-*` actions;
# this script is the compositor-agnostic fallback and matches the qtile-era
# binds. Files land in $SCREENSHOT_DIR (default ~/Pictures).
set -u

dir="${SCREENSHOT_DIR:-$HOME/Pictures}"
mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d-%H%M%S).png"

case "${1:-full}" in
    full)
        grim "$out"
        ;;
    area)
        grim -g "$(slurp)" "$out"
        ;;
    annotate)
        if ! command -v satty >/dev/null 2>&1; then
            echo "screenshot.sh: satty is not installed (use: noctalia msg screenshot-annotate)" >&2
            exit 1
        fi
        grim -g "$(slurp)" -t ppm - | satty -f -
        ;;
    *)
        echo "usage: $0 [full|area|annotate]" >&2
        exit 2
        ;;
esac
