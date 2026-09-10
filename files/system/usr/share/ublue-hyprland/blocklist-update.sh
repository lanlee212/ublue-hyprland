#!/usr/bin/env bash
# ublue-hyprland: refresh the DNS blocklist used by the local filtering resolver
# (dnsmasq, see /etc/dnsmasq.d/ublue-filter.conf).
#
# Runs:
#   - at image build time (bakes the list in, so filtering works offline on
#     first boot), and
#   - weekly via ublue-blocklist-update.timer.
#
# Never leaves the resolver without a list file: on any failure the previous
# list is kept (and an empty file is created if none exists yet), because a
# missing addn-hosts file makes dnsmasq refuse to start.

set -u

LIST_URL="${LIST_URL:-https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts}"
DEST_DIR=/etc/dnsmasq.hosts
DEST="$DEST_DIR/porn.hosts"

mkdir -p "$DEST_DIR"
TMP="$(mktemp "$DEST.XXXXXX")" || exit 1
trap 'rm -f "$TMP"' EXIT

ok=0
if curl -fsSL --retry 3 --connect-timeout 15 -o "$TMP" "$LIST_URL"; then
    if grep -q '^0\.0\.0\.0' "$TMP"; then
        chmod 644 "$TMP"
        mv -f "$TMP" "$DEST"
        ok=1
        echo "blocklist: updated $DEST ($(grep -c '^0\.0\.0\.0' "$DEST") blocked domains)"
    else
        echo "blocklist: fetched file contains no block entries — keeping previous list" >&2
    fi
else
    echo "blocklist: download failed ($LIST_URL) — keeping previous list" >&2
fi

if [ "$ok" -eq 0 ] && [ ! -e "$DEST" ]; then
    : > "$DEST"          # keep dnsmasq startable
    echo "blocklist: created empty $DEST (no list available yet)" >&2
fi

# Reload the resolver if it is running (no-op during image build).
if systemctl is-active --quiet dnsmasq.service 2>/dev/null; then
    systemctl reload dnsmasq.service 2>/dev/null || true
fi

exit 0
