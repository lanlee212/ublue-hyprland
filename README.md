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
| xdg-desktop-portal-hyprland | COPR `lionheartp/Hyprland` | 1.4.1 |
| Noctalia | Fedora default repos | 5.0.1 |
| ghostty | COPR `scottames/ghostty` | latest |
| sddm | Fedora default repos | 0.21.0 |

Plus a lean desktop runtime the base image doesn't ship: pipewire(+pulse), wireplumber,
polkit + lxpolkit agent, power-profiles-daemon.

## The shipped config (all of it)

`/usr/share/ublue-hyprland/config/hypr/hyprland.lua` is copied to `~/.config/hypr/` on
first login (no-clobber) by `/etc/profile.d/ublue-hyprland.sh`. It only:
- autostarts the polkit agent + `noctalia`
- sets rounding 0 (flat, Noctalia-style), hides the logo/splash
- binds a basic set: SUPER+Return ghostty, SUPER+D Noctalia launcher,
  SUPER+arrows/space focus, SUPER+Q/F/T, SUPER(+SHIFT)+1..9 workspaces

Noctalia generates its own config (setup wizard) on first run — nothing shipped for it.

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

- [x] Recipe scaffold (local, no CI yet)
- [ ] First build + container validation
- [ ] GitHub Actions CI (BlueBuild) + cosign signing keys
- [ ] Signing module added to recipe
- [ ] Optional: bootc-image-builder ISO

## Local layout

```
recipes/recipe.yml                 # build recipe (modules: files → dnf → script)
files/system/etc/profile.d/        # first-login config installer
files/system/usr/share/ublue-hyprland/config/hypr/hyprland.lua
```
