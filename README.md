# AnonSurf for Kali Linux

<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/1dbf7ac1-7c51-40c2-b4cf-64a702573541" />



[![Kali Linux](https://img.shields.io/badge/Kali-Rolling-57721B?logo=linux&logoColor=white)](https://www.kali.org/)
[![Version](https://img.shields.io/badge/version-6.0.1%2Bparrot2--0kali8-blue)](https://github.com/wickednull/anonsurf/releases)
[![Architecture](https://img.shields.io/badge/architecture-amd64-lightgrey)](https://github.com/wickednull/anonsurf/releases)
[![License](https://img.shields.io/badge/license-GPL--3.0%2B-green)](LICENSE)
[![Lintian](https://img.shields.io/badge/lintian-clean-brightgreen)](https://github.com/wickednull/anonsurf/releases)
[![Tests](https://img.shields.io/badge/tests-Kali%20VM%20%2B%20host-brightgreen)](https://github.com/wickednull/anonsurf)
[![Stars](https://img.shields.io/github/stars/wickednull/anonsurf.svg?style=social)](https://github.com/wickednull/anonsurf/stargazers)
[![Contributors](https://img.shields.io/github/contributors/wickednull/anonsurf.svg)](https://github.com/wickednull/anonsurf/graphs/contributors)

A Kali-native port of [Parrot AnonSurf 6](https://gitlab.com/parrotsec/packages/anonsurf/).
AnonSurf routes supported TCP traffic and DNS lookups through Tor using transparent
proxying, with a kill-switch, transactional rollback, and boot recovery after a crash.

> **Unofficial project — not affiliated with Kali Linux or Parrot Security.**
> This is an independently maintained, Kali-branded rebuild of the upstream
> AnonSurf source. It is **not** affiliated with, endorsed by, sponsored by, or
> connected to Offensive Security, the Kali Linux project, Parrot Security, or
> the Parrot Project. All trademarks are the property of their respective
> owners. See [LEGAL.md](LEGAL.md) for the full disclaimer.

---

## Features

- **Kali-native branding** — `org.kali.Anonsurf` desktop/D-Bus/QML identifiers.
- **No package collision** — the DNS helper is installed as
  `/usr/lib/anonsurf/dnstool` with an `anonsurf-dnstool` symlink, so it does not
  conflict with `krbrelayx`.
- **Transactional start** — firewall, IPv6, DNS and `torrc` are restored if any
  step fails.
- **Boot recovery** — `anonsurf-recovery.service` is explicitly enabled because
  Kali's default systemd preset disables all services.
- **Bootstrap-aware** — DNS is switched to Tor only after Tor finishes
  bootstrapping, so a slow first start never leaves you with a dead resolver.
- **Fast stall and circuit recovery** — if Tor stalls at 10% (`conn_done`) for
  12 seconds, AnonSurf drops the bad guard and rotates circuits immediately,
  falling back to a full Tor restart only if that does not help.
- **Automatic bridge fallback** — if direct relays are blocked by the local
  network or ISP for 20 seconds, AnonSurf switches to bundled obfs4 bridges.
  `obfs4proxy` is installed automatically.
- **No outage on failed start** — the firewall and DNS switch happen only after
  Tor has bootstrapped and built a usable circuit, so a blocked start leaves
  your clearnet connection intact.
- **Unprivileged GUI** — the Qt 6/QML interface talks to systemd over D-Bus with
  polkit, rather than running as root.
- **Clean packaging** — Debian `3.0 (quilt)` source, clean binary and source
  lintian, verified `dpkg-source -x` rebuild.

---

## Requirements

- Kali Linux **Rolling**, updated to current `kali-rolling` packages.
- `amd64` architecture.
- Qt **6.11.2+** for the GUI. The frozen `kali-last-snapshot` cloud image ships
  Qt 6.10.2 and cannot run the GUI; run `apt update && apt full-upgrade` first.
- Root via `sudo` for installation and lifecycle changes.

The installer pulls in `tor`, `nyx`, `iptables`, `network-manager`, `procps`,
`sudo`, and the Qt/QML runtime packages automatically.

---

## Quick install

```bash
git clone https://github.com/wickednull/anonsurf.git
cd anonsurf
./install.sh
```

The script verifies `SHA256SUMS`, then installs all four `.deb` packages from
`dist/` with `apt`.

### Manual install

```bash
cd anonsurf
sha256sum -c SHA256SUMS
sudo apt update
sudo apt install -y ./dist/*.deb
```

---

## Usage

```bash
anonsurf status --json        # health, DNS mode, Tor state
sudo anonsurf start           # route through Tor
sudo anonsurf stop            # restore clearnet
sudo anonsurf restart         # rebuild routes
sudo anonsurf changeid        # request a new Tor identity
anonsurf ip --json            # verify public IP / Tor exit
anonsurf monitor              # Nyx Tor monitor
anonsurf boot enable          # enable startup integration
anonsurf boot disable         # disable startup integration
```

Launch the desktop interface with `anonsurf-gui`, or open **AnonSurf** from the
Kali application menu. While active, `anonsurf status` reports DNS mode `tor`.

---

## What the packages contain

| Package | Purpose |
|---|---|
| `anonsurf` | Daemon, firewall/DNS/IPv6 logic, systemd units, config |
| `anonsurf-cli` | `anonsurf` command, man page, shell completions |
| `anonsurf-gui` | Qt 6/QML graphical interface |
| `anonsurf-gtk` | Empty transitional package for old GTK installs |

The source release in `dist/` consists of the upstream orig tarball, the `.dsc`,
and the Debian tarball containing all Kali packaging patches.

---

## Verify the download

```bash
sha256sum -c SHA256SUMS
```

Every binary and source artifact in `dist/` is listed in `SHA256SUMS`.

---

## Build from source

```bash
sudo apt install -y debhelper cmake g++ golang-go bash-completion \
  qt6-base-dev qt6-declarative-dev qml6-module-qtquick-shapes

dpkg-source -x dist/anonsurf_6.0.1+parrot2-0kali8.dsc
cd anonsurf-6.0.1+parrot2
dpkg-buildpackage -us -uc -b
```

`dpkg-buildpackage -S -us -uc` rebuilds the source package instead.

---

## Troubleshooting

**No DNS immediately after starting.** The daemon now waits for Tor bootstrap
and prints `Waiting for Tor bootstrap (N%)`. It only writes `nameserver
127.0.0.1` once Tor is ready. First bootstrap can take several minutes on a
fresh machine.

**Start hangs at `Waiting for Tor bootstrap (10%)`.** Tor has connected to a
guard relay but cannot complete the handshake with it — usually a dead guard or
one on a port blocked by your network. AnonSurf detects a 12-second stall,
prints `Tor stalled at 10%, rotating guard`, drops the bad guard and builds new
circuits. If direct relays stay blocked for 20 seconds, it prints
`Direct Tor relays blocked, switching to bridges` and bootstraps over the
bundled obfs4 bridges instead. `FascistFirewall 1` is disabled in bridge mode
so bridges on non-443 ports also work.

**Start succeeds but sites will not load.** Tor can report `100%` bootstrap
yet fail every stream with `waiting for circuit` if its guard is bad. AnonSurf
now checks `circuit-status` over the control port and restarts Tor if no
general-purpose circuit is built. You may see `Waiting for Tor circuits` or
`Tor circuits not ready, restarting Tor` before success.

**The GUI opens by itself at login.** That is KDE session restore, not
AnonSurf starting at boot. The GUI now opts out of session restore; if an old
session still restores it, close the window once before logging out, or clear
it in **System Settings → Session and Startup**.

**Browser says `DNS_PROBE_POSSIBLE` while AnonSurf is active.** Disable Secure
DNS / DNS-over-HTTPS in Chrome or Brave (`chrome://settings/security` or
`brave://settings/security`), then restart the browser. DoH bypasses the system
resolver that AnonSurf controls.

**A specific site still will not load.** Some sites block Tor exit nodes. Test
with `https://kali.org` first; if that works, the routing is healthy.

**Recovery after a hard shutdown.** Check with:

```bash
systemctl status anonsurf-recovery.service
```

It is enabled at install time and restores `torrc`, DNS, IPv6 and firewall state
before Tor starts at boot.

**Full rollback:**

```bash
sudo anonsurf stop
sudo apt purge -y anonsurf anonsurf-cli anonsurf-gui anonsurf-gtk
sudo apt --fix-broken install
```

---

## Notes on routing

- TCP is redirected to Tor's `TransPort` (`127.0.0.1:9040`).
- UDP DNS is redirected to Tor's `DNSPort` (`127.0.0.1:53`).
- IPv6 is disabled while active and restored on stop.
- Private networks and loopback are exempt from redirection.
- Existing connections are not migrated into Tor; applications must reconnect.
- Arbitrary UDP is not carried through Tor.

---

## Credits

Based on the original AnonSurf work by the Parrot Security team.

## License

GPL-3.0+ as declared in the packaged copyright metadata. See [LICENSE](LICENSE)
for the upstream license text.
