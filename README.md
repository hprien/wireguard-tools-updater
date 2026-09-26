# wireguard-tools-updater

Keeps the [wireguard-tools](https://git.zx2c4.com/wireguard-tools) userspace tools (`wg`, `wg-quick`) up to date by building the newest release from source — instead of waiting for distro packages.

## Scripts

- **`wg-update.sh`** — compares the installed version against the newest upstream git tag and installs it if it differs or is missing. If already up to date, exits without touching the running tunnel.
- **`wg-downgrade.sh`** — deliberately installs the *second*-newest release, to test that `wg-update.sh` detects and repairs an outdated installation.

## Usage

```bash
sudo ./wg-update.sh
```

To test the update path end to end:

```bash
sudo ./wg-downgrade.sh   # downgrade to second-newest
sudo ./wg-update.sh      # upgrades back to newest
sudo ./wg-update.sh      # second run: "up to date, nothing to do"
```

## Requirements

- root (build, install, and tunnel control)
- `git`, `make`, a C compiler

No existing wireguard-tools installation or tunnel is required — the scripts work on a bare system. If `/etc/wireguard/wg0.conf` exists, the tunnel is brought down before installing and back up (with autostart enabled) afterwards; otherwise tunnel management is skipped entirely.

The WireGuard kernel module is not touched — it ships with your kernel. These scripts only update the userspace tools.