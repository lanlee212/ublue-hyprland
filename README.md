# ublue-hyprland

Minimal Hyprland + Noctalia desktop image, built with [BlueBuild](https://blue-build.org) on top of
[Universal Blue's lean base](https://github.com/ublue-os/image-template) (`ghcr.io/ublue-os/base-main`).

> Two sessions, one desktop: Hyprland (default) and Noctalia's own compositor
> [Umbriel](https://docs.noctalia.dev/umbriel/), both running the Noctalia shell
> (bar/launcher/session/OSD/lock/notifications/wallpaper) with the same qtile-parity
> keymap, 5 workspaces, 4 scratchpads and the flat/no-rounding look. The Noctalia
> Greeter is the login screen.

## What's inside

| Piece | Source | Version (F44) |
|---|---|---|
| Hyprland | COPR `lionheartp/Hyprland` | 0.56.2 |
| hyprland-guiutils | COPR `lionheartp/Hyprland` | 0.2.2 |
| xdg-desktop-portal-hyprland | COPR `lionheartp/Hyprland` | 1.4.1 |
| Noctalia | Fedora repos + `noctalia-git` | 5.1.0-git |
| Umbriel (compositor) | Terra (`umbriel-nightly`) | 0.1.0 (git) |
| xwayland-satellite (Umbriel X11) | Fedora (dep of umbriel-nightly) | 25.x |
| ghostty | COPR `scottames/ghostty` | latest |
| brave-origin / helium | Brave official repo / COPR `imput/helium` | 1.94.x |
| pyprland | PyPI (pip, pinned, `--prefix=/usr`) | 3.4.4 |
| greetd + Noctalia Greeter | Fedora / Terra (`noctalia-greeter-git`) | 0.10.3 / 1.5.0 |

Plus a lean desktop runtime the base image doesn't ship: pipewire(+pulse), wireplumber,
polkit, power-profiles-daemon.

**RustDesk** (remote desktop) comes from the official GitHub release RPM, pinned to a version
in the recipe — nothing in Fedora or Terra packages it. The RPM also ships
`rustdesk.service` for unattended *inbound* access; it is deliberately left **disabled**, since
letting others connect into this machine is a per-machine decision:

```sh
sudo systemctl enable --now rustdesk.service    # only if you want inbound unattended access
```

## The shipped config (all of it)

`/usr/share/ublue-hyprland/config/hypr/hyprland.lua` is copied to `~/.config/hypr/` on
first login (no-clobber) by `/etc/profile.d/ublue-hyprland.sh`. It only:
- autostarts the polkit agent + `noctalia`
- sets rounding 0 (flat, Noctalia-style), hides the logo/splash
- binds a basic set: SUPER+Return ghostty, SUPER+D Noctalia launcher,
  SUPER+arrows/space focus, SUPER+Q/F/T, SUPER(+SHIFT)+1..9 workspaces

`/usr/share/ublue-hyprland/config/umbriel/config.toml` ports that same keymap to Umbriel's
TOML format — master layout with the qtile sizing, 4 named scratchpads (term/fm/sol/gam),
the Noctalia palette as an optional include, and a screenshot submap — and is copied to
`~/.config/umbriel/` on first login the same way. Both sessions bind the shared helper
scripts in `/usr/share/ublue-hyprland/scripts/`: `lock-suspend.sh` (SUPER+L: pause media,
then lock & suspend) and `screenshot.sh` (grim/slurp, wlr-screencopy — no portal).

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

**Greeter appearance sync needs pkexec.** Noctalia ≥5.1 picks the constrained sync path
(`noctalia-greeter-apply-appearance --sync <staging>`), which the helper only accepts when
it runs under `pkexec` — that is what gives it the verified `PKEXEC_UID`. Leaving
`[shell.greeter_sync] privilege_command` set to `run0` (or sudo/doas) makes every sync fail:

```
[WRN] [greeter-sync] greeter sync failed: [ERR] [apply-appearance] --sync must be invoked through pkexec
```

so `privilege_command` stays unset on this image. `sudo noctalia-greeter passwordless-sync
enable <user>` installs the narrow managed polkit rule for the constrained action only
(active local sessions, that one action — not a general sudo rule), which removes the
password prompt on every wallpaper change; `... disable <user>` reverts it.

## Credentials: Secret Service (gnome-keyring)

Apps that store passwords ask the session for a Secret Service
(`org.freedesktop.secrets`). The image ships **gnome-keyring + gnome-keyring-pam** for it;
without those packages every app silently fails to persist credentials and re-prompts each
session. `/etc/pam.d/greetd` already carries the hooks (dash-prefixed, so they are ignored
while the module is missing):

```
-auth    optional pam_gnome_keyring.so
-session optional pam_gnome_keyring.so auto_start
```

That makes login unlock the keyring with the login password — for both the Hyprland and the
Umbriel session, since both come through greetd. Two caveats worth knowing:

- Auto-unlock only works when the keyring's password equals the login password. A keyring
  carried over from another machine (or created with a different/blank password) stays
  locked, and a locked collection reports an error instead of prompting — there is no
  prompter in these sessions (`org.gnome.keyring.SystemPrompter` is a gnome-shell thing).
  Fix: move `~/.local/share/keyrings/` aside and let the next login create a fresh login
  keyring with the login password.
- Verify from a terminal: `secret-tool store --label=test test key value` then
  `secret-tool lookup test key` (libsecret's CLI, already in the image).

## Virtualisation (QEMU/KVM)

`qemu` in the package list is the metapackage — the emulator itself, for x86_64 *and* the
other targets, with the GTK/SDL/SPICE displays, `virtiofsd` and the OVMF firmware. That part
already works on its own: `qemu-system-x86_64 -accel kvm` runs hardware-accelerated (verified
by booting a cirros cloud image — DHCP lease, cloud-init, serial console). What a VM workflow
actually expects on top of it is the management layer, which this image now ships:

```
libvirt-daemon-kvm   virtqemud + the qemu driver + libvirt's default NAT network
libvirt-client       virsh
virt-install         create guests from the CLI
virt-manager         GUI
virt-viewer          console viewer (SPICE/VNC)
swtpm                emulated TPM (Windows 11 guests)
edk2-ovmf            UEFI firmware for guests (was only arriving as a transitive dep)
```

Permissions: guests need a CPU with AMD-V/VT-x exposed (`svm`/`vmx` in `lscpu`'s flags) plus
`kvm_amd`/`kvm_intel` loaded — then `/dev/kvm` is all that matters, and Fedora ships it mode
`0666`, so `qemu:///session` needs no group membership. libvirt's modular daemons are
socket-activated and Fedora's presets enable them at install time (the
`/etc/systemd/system/sockets.target.wants/` symlinks are part of the image), so the recipe
enables nothing extra. For `qemu:///system` without a polkit prompt, add yourself to the
libvirt group once:

```sh
sudo usermod -aG libvirt $USER      # log out / in afterwards
```

Quick start:

```sh
virt-install --name test --memory 2048 --vcpus 2 --disk size=20 \
  --cdrom ~/Downloads/Fedora-Workstation.iso --osinfo detect=on,require=off
virsh list --all
virt-manager
```

**The default NAT network needs one image-provided fix to come up.** `libvirt-daemon-common`
ships `/var/lib/libvirt` as RPM file entries, but an ostree/bootc image carries no `/var`
content — so on the target the directory doesn't exist and the libvirt daemons create it at
first start, inheriting the parent's `var_lib_t` label. Fedora's policy expects `virt_var_lib_t`
there, and the confined `virtnetworkd_t` cannot write `var_lib_t`:

```
AVC avc: denied { write } for comm="rpc-virtnetwork" name="libvirt"
    scontext=sys…:virtnetworkd_t tcontext=sys…:var_lib_t tclass=dir
virtnetworkd: cannot create directory /var/lib/libvirt/dnsmasq: Permission denied
```

which surfaces to the user as `Requested operation is not valid: network 'default' is not
active` — the NAT bridge is never built. The image therefore ships
`/usr/lib/tmpfiles.d/ublue-libvirt-selinux.conf` (`d` + `z`), so the path is created and
re-labelled on every boot. On a system that predates that rule:

```sh
sudo restorecon -Rv /var/lib/libvirt      # label it virt_var_lib_t
sudo virsh net-start default              # Autostart is already 'yes', so this sticks
```

## Printing & scanning

**The printer is a Brother MFC-L2740DW — a Gen1/GDI machine**, which is why nothing "just
works": it understands neither PCL nor PostScript, so CUPS's generic drivers print garbage
and only the vendor driver or **brlaser** (Fedora `printer-driver-brlaser`, shipped here) is
usable. CUPS itself is in the base image and does detect the device on USB
(`usb://Brother/MFC-L2740DW series?serial=…`) — what was missing was a *queue* and a tool to
create one:

    printer-driver-brlaser   the driver that actually works with this printer
    system-config-printer    GUI to add/tune queues (polkit prompts, no terminal needed)
    cups-browsed             IPP/AirPrint discovery when the printer is on the network
    sane-airscan             driverless scanning (eSCL/WSD)
    simple-scan              scanning GUI

One command adds the queue (it finds the USB URI and the closest brlaser PPD itself):

```sh
sudo /usr/share/ublue-hyprland/scripts/add-brother-printer.sh
lp -d Brother /etc/nsswitch.conf     # quick test page
```

If the test page comes out garbled, the family PPD is the thing to change — `brl2710w.ppd`
(MFC-L2710DW series) is the default, `brl2700w.ppd` (MFC-L2700DW series) the fallback; both
are in `/usr/lib/cups/driver/brlaser.drv`. Over Ethernet/Wi-Fi no driver is needed at all —
the printer speaks IPP:

```sh
sudo lpadmin -p Brother -E -v ipp://<printer-ip>/ipp/print -m everywhere
```

Scanning works over the network via `sane-airscan` (`simple-scan` as the GUI); the Gen1
Brother USB scanner is not covered by open-source backends, so scan over the LAN.

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
  Currently blocked there: `f95zone.to`, `janitorai.com`, `chub.ai`, `chubusercontent.com`,
  `saucepan.ai`.
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
- [x] Greeter sync kept working after the `noctalia-git` move (pkexec, not run0)
- [x] Umbriel session: Hyprland config ported to `umbriel/config.toml` + shipped
- [x] Virtualisation: QEMU/KVM (already working) + libvirt, virsh, virt-install, virt-manager, swtpm
- [x] Printing + scanning: Brother MFC-L2740DW via brlaser (+ system-config-printer, sane-airscan)
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
files/system/usr/share/ublue-hyprland/config/umbriel/config.toml   # Hyprland config ported to Umbriel TOML
files/system/usr/share/ublue-hyprland/scripts/lock-suspend.sh      # SUPER+L: pause media + lock & suspend
files/system/usr/share/ublue-hyprland/scripts/screenshot.sh        # grim/slurp screenshots (full|area|annotate)
files/system/usr/share/ublue-hyprland/scripts/add-brother-printer.sh  # CUPS queue for the MFC-L2740DW (brlaser)
files/system/usr/share/ublue-hyprland/config/greetd/config.toml
files/system/usr/share/ublue-hyprland/config/wayland-sessions/hyprland.desktop
files/system/usr/share/ublue-hyprland/session-hyprland.sh
```
