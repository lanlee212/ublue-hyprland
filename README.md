# ublue-hyprland

Minimal Hyprland + Noctalia desktop image, built with [BlueBuild](https://blue-build.org) on top of
[Universal Blue's lean base](https://github.com/ublue-os/image-template) (`ghcr.io/ublue-os/base-main`).

> Basic by design: stock Hyprland behavior + the Noctalia shell autostarted at login.
> No qtile-parity keymap, no OneDark theming, no scratchpad fleet — just a clean
> Hyprland desktop whose shell (bar/launcher/session/OSD/lock/notifications/wallpaper)
> is Noctalia.

## What's inside

| Piece | Source | Version (F44) |
|---|---|---|
| Hyprland | COPR `lionheartp/Hyprland` | 0.56.2 |
| hyprland-guiutils | COPR `lionheartp/Hyprland` | 0.2.2 |
| xdg-desktop-portal-hyprland | COPR `lionheartp/Hyprland` | 1.4.1 |
| Noctalia | Fedora default repos | 5.0.1 |
| ghostty | COPR `scottames/ghostty` | latest |
| brave-origin | Brave official repo | 1.94.x |
| pyprland | PyPI (pip, pinned, `--prefix=/usr`) | 3.4.4 |
| greetd + Noctalia Greeter | Fedora / Terra (fyralabs) | 0.10.3 / 1.3.1 |

Plus a lean desktop runtime the base image doesn't ship: pipewire(+pulse), wireplumber,
polkit + mate-polkit agent (GNOME-style auth dialog), power-profiles-daemon.

## The shipped config (all of it)

`/usr/share/ublue-hyprland/config/hypr/hyprland.lua` is copied to `~/.config/hypr/` on
first login (no-clobber) by `/etc/profile.d/ublue-hyprland.sh`. It only:
- autostarts the polkit agent + `noctalia`
- sets rounding 0 (flat, Noctalia-style), hides the logo/splash
- binds a basic set: SUPER+Return ghostty, SUPER+D Noctalia launcher,
  SUPER+arrows/space focus, SUPER+Q/F/T, SUPER(+SHIFT)+1..9 workspaces

Noctalia generates its own config (setup wizard) on first run — nothing shipped for it.

The login screen is the Noctalia Greeter (greetd), matching the shell's visual language:
`/usr/share/ublue-hyprland/config/greetd/config.toml` is copied to `/etc/greetd/config.toml`
at build time and launches `noctalia-greeter-session` as the `greetd` user. sddm is not
installed. Because greetd execs the session directly (no profile sourcing), the Hyprland
session entry points at a wrapper (`/usr/share/ublue-hyprland/session-hyprland.sh`) that
sources /etc/profile first — keeping profile.d first-login installers working.

## Install (rebase)

On an existing Fedora Atomic install:

```sh
# 1. unsigned first (installs our signing keys/policies once CI signing exists)
rpm-ostree rebase ostree-unverified-registry:ghcr.io/lanlee212/ublue-hyprland:latest
systemctl reboot
# 2. then signed (after the signing module + keys are added)
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/lanlee212/ublue-hyprland:latest
systemctl reboot
```

## Status / roadmap

- [x] Recipe scaffold
- [x] First CI build pipeline (BlueBuild action v1.12.0, daily 06:00 UTC + on push)
- [x] Cosign signing keys (pub in repo, private key in SIGNING_SECRET)
- [x] First successful signed image build ✓ (ghcr.io/lanlee212/ublue-hyprland:latest, verified with cosign.pub)
- [ ] Smoke test (VM rebase)
- [ ] Optional: bootc-image-builder ISO

## Local layout

```
recipes/recipe.yml                 # build recipe (modules: files → dnf → script)
files/system/etc/profile.d/        # first-login config installer
files/system/usr/share/ublue-hyprland/config/hypr/hyprland.lua
files/system/usr/share/ublue-hyprland/config/greetd/config.toml
files/system/usr/share/ublue-hyprland/config/wayland-sessions/hyprland.desktop
files/system/usr/share/ublue-hyprland/session-hyprland.sh
```
