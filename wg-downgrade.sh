#!/bin/bash
set -euo pipefail

REPO="https://git.zx2c4.com/wireguard-tools"
WG_IFACE="wg0"
WG_CONF="/etc/wireguard/$WG_IFACE.conf"

# --- get the two most recent release tags ---
mapfile -t tags < <(git ls-remote --tags --refs "$REPO" | sed 's|.*refs/tags/||' | sort -V | tail -2)

if [ "${#tags[@]}" -lt 2 ]; then
    echo "error: fewer than two tags found upstream, cannot pick second-newest" >&2
    exit 1
fi

latest=${tags[-1]#v}
previous=${tags[-2]#v}
installed=$(wg --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || installed=""

echo "installed: ${installed:-none}"
echo "latest:    $latest"
echo "previous:  $previous  <-- installing this"

if [ -n "$installed" ] && [ "$installed" = "$previous" ]; then
    echo "already on the second-newest version, nothing to do"
    exit 0
fi

# --- install the outdated release ---
# bring the tunnel down if one exists (skipped when wg0 isn't configured
# or wireguard-tools isn't installed yet)
[ -f "$WG_CONF" ] && sudo wg-quick down "$WG_IFACE" 2>/dev/null || true

rm -rf /tmp/wireguard-tools-build

# -c advice.detachedHead=false suppresses the "detached HEAD" notice that
# git prints when --branch points at a tag (which is intentional here)
git -c advice.detachedHead=false clone --depth 1 --branch "v$previous" "$REPO" /tmp/wireguard-tools-build
make -C /tmp/wireguard-tools-build/src
sudo make -C /tmp/wireguard-tools-build/src install

rm -rf /tmp/wireguard-tools-build

# start and autostart wg again (only when a tunnel config exists)
if [ -f "$WG_CONF" ]; then
    sudo wg-quick up "$WG_IFACE"
    sudo systemctl enable "wg-quick@$WG_IFACE"
fi

# --- verify ---
installed=$(wg --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo "now installed: $installed"
if [ "$installed" = "$previous" ]; then
    echo "downgrade to second-newest version successful"
    echo "run ./wg-update.sh to verify it detects and upgrades to $latest"
else
    echo "warning: expected $previous but found $installed" >&2
    exit 1
fi