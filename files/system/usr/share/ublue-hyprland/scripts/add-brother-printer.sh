#!/usr/bin/env bash
# Add the Brother MFC-L2740DW to CUPS — run as root:
#
#     sudo /usr/share/ublue-hyprland/scripts/add-brother-printer.sh [queue-name]
#
# Why a script: the L2740DW is a Gen1 (GDI) Brother, so it understands neither
# PCL nor PostScript — the generic drivers print garbage. brlaser (Fedora's
# printer-driver-brlaser) is the open driver that works; this picks the closest
# brlaser PPD for the L27x0 family and the printer's actual USB URI (which
# contains the serial, so hard-coding it breaks on a different unit).
#
# If the test page comes out garbled, the family PPD is the variable to change:
#   brl2710w.ppd (MFC-L2710DW series, default)  brl2700w.ppd (MFC-L2700DW series)
#
# Networked instead of USB? The queue URI becomes the printer's IPP endpoint and
# no driver is needed at all (the printer speaks IPP/AirPrint):
#   sudo lpadmin -p Brother -E -v ipp://<printer-ip>/ipp/print -m everywhere
set -eu

NAME="${1:-Brother}"
SKIP_PPD=brl2710w.ppd

if [ "$(id -u)" != "0" ]; then
    echo "run me as root:  sudo $0 [$NAME]" >&2
    exit 1
fi

URI="$(lpinfo -v | awk '/^direct usb:\/\/Brother/ {print $2; exit}')"
if [ -z "$URI" ]; then
    echo "No Brother printer on USB." >&2
    echo "Connected by Ethernet/Wi-Fi? Add it driverlessly instead:" >&2
    echo "  sudo lpadmin -p $NAME -E -v ipp://<printer-ip>/ipp/print -m everywhere" >&2
    exit 1
fi

PPD="drv:///brlaser.drv/$SKIP_PPD"
if ! lpinfo -m | grep -q "$PPD"; then
    PPD="$(lpinfo -m | awk '/brlaser.drv.*L27[0-9]0.*series/ {print $1; exit}')"
fi

echo "printer : $URI"
echo "driver  : $PPD"
lpadmin -p "$NAME" -E -v "$URI" -m "$PPD" -o printer-is-shared=false
lpadmin -d "$NAME"
echo
echo "Added. Check and test:"
echo "  lpstat -p $NAME"
echo "  lp -d $NAME /etc/nsswitch.conf     # a quick text page"
echo "GUI for options/scanning:  system-config-printer , simple-scan"
