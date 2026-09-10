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
| greetd + Noctalia Greeter | Fedora / Terra (fyralabs) | 0.10.3 / 1.5.0 |

Plus a lean desktop runtime the base image doesn't ship: pipewire(+pulse), wireplumber,
polkit, power-profiles-daemon.

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

**SELinux and the greeter state dir.** Noctalia's *Settings → Security → Noctalia Greeter →
Sync Now* pushes wallpaper/palette to the greeter by writing `/var/lib/noctalia-greeter/`
(`sync.toml` + the synced wallpapers). The greeter runs confined as `xdm_t`, and Fedora's
policy gives `xdm_t` only **read** access to the default `var_lib_t` label — so the greeter
could display the synced appearance but every save failed:

```
[WRN] [greeter-config] failed to replace '/var/lib/noctalia-greeter/sync.toml': Permission denied
[WRN] [greeter-surface] failed to save sync.toml (check permissions on /var/lib/noctalia-greeter/sync.toml)
```

i.e. session/scheme choices made on the login screen were silently dropped. The image ships
the same label `greetd-selinux` gives `/var/lib/greetd` (`xdm_var_lib_t`), via an fcontext
rule plus a tmpfiles `d`+`Z` line that re-labels the directory on every boot. A distro without
SELinux enforcement (e.g. Arch) never sees this, which is why it only showed up on this image.

## DNS content filter (adult-content blocklist)

Filtering is done at DNS level with a local resolver, so it covers every app on the
system without per-app rules:

- **dnsmasq** answers on `127.0.0.1:53`, loopback-only (`bind-interfaces` — never an
  open resolver), with upstream queries to 9.9.9.9 / 1.1.1.1.
- The blocklist is **StevenBlack's porn-only hosts list** (≈77k domains), baked into
  the image at build time (filters from first boot, works offline) and refreshed
  **weekly** by `ublue-blocklist-update.timer` → `blocklist-update.sh`
  (atomic replace + `systemctl reload dnsmasq`; a failed download keeps the old list).
- `systemd-resolved` forwards everything to it (`Domains=~.`), and NetworkManager runs
  with `dns=none` so DHCP-provided DNS servers can't take precedence and bypass the
  filter.
- **Hand-picked extras** live in `etc/dnsmasq.d/ublue-custom-blocks.conf` — separate from
  the auto-refreshed list, so weekly updates can never drop them. Entries use
  `address=/<domain>/0.0.0.0`, which blocks the domain **and all its subdomains**.
  Currently blocked there: `f95zone.to`, `janitorai.com`, `chub.ai`, `chubusercontent.com`.
  Adding a site = one line + rebuild (or drop the file onto a running system's
  `/etc/dnsmasq.d/` and `systemctl reload dnsmasq`).

Verify on a running system:

```sh
dig +short @127.0.0.1 pornhub.com   # -> 0.0.0.0
dig +short @127.0.0.1 example.com   # -> real IP
systemctl status dnsmasq ublue-blocklist-update.timer
grep -c '^0\.0\.0\.0' /etc/dnsmasq.hosts/porn.hosts
```

Known limits (state of the art for DNS filtering): a VPN (WireGuard/OpenVPN) routes DNS
through its own tunnel and bypasses this entirely, and browser-internal DoH/DoT
resolvers can evade a plain DNS filter unless they're blocked/hardened separately.

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
- [x] DNS content filter (dnsmasq + StevenBlack porn-only blocklist, weekly auto-refresh)
- [x] Noctalia Greeter appearance sync (SELinux label for the greeter state dir)
- [ ] Smoke test (VM rebase)
- [ ] Optional: bootc-image-builder ISO

## Local layout

```
recipes/recipe.yml                 # build recipe (modules: files → dnf → script)
files/system/etc/profile.d/        # first-login config installer
files/system/etc/selinux/targeted/contexts/files/file_contexts.local  # greeter state dir -> xdm_var_lib_t
files/system/usr/lib/tmpfiles.d/noctalia-greeter-selinux.conf  # d + Z: greetd ownership + relabel each boot
files/system/etc/dnsmasq.d/ublue-filter.conf        # filtering resolver config
files/system/etc/NetworkManager/conf.d/90-ublue-dns.conf  # dns=none (keep the filter authoritative)
files/system/etc/systemd/resolved.conf.d/50-ublue-dns.conf # resolved → 127.0.0.1
files/system/usr/lib/systemd/system/ublue-blocklist-update.{service,timer}
files/system/usr/share/ublue-hyprland/blocklist-update.sh  # fetch + reload (build + weekly)
files/system/usr/share/ublue-hyprland/config/hypr/hyprland.lua
files/system/usr/share/ublue-hyprland/config/greetd/config.toml
files/system/usr/share/ublue-hyprland/config/wayland-sessions/hyprland.desktop
files/system/usr/share/ublue-hyprland/session-hyprland.sh
```
