#!/bin/bash
set -euo pipefail

REPO="https://git.zx2c4.com/wireguard-tools"
WG_IFACE="wg0"
WG_CONF="/etc/wireguard/$WG_IFACE.conf"

# --- version check ---
installed=$(wg --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) || installed=""

# latest upstream tag, without cloning
latest=$(git ls-remote --tags --refs "$REPO" | sed 's|.*refs/tags/||' | sort -V | tail -1)
latest=${latest#v}

echo "installed: ${installed:-none}  latest: $latest"

if [ -n "$installed" ] && [ "$installed" = "$latest" ]; then
    echo "wireguard-tools is up to date, nothing to do"
    exit 0
fi

# --- update ---
# bring the tunnel down if one exists (skipped when wg0 isn't configured
# or wireguard-tools isn't installed yet)
[ -f "$WG_CONF" ] && wg-quick down "$WG_IFACE" 2>/dev/null || true

rm -rf /tmp/wireguard-tools-build

# -c advice.detachedHead=false suppresses the "detached HEAD" notice that
# git prints when --branch points at a tag (which is intentional here)
git -c advice.detachedHead=false clone --depth 1 --branch "v$latest" "$REPO" /tmp/wireguard-tools-build
make -C /tmp/wireguard-tools-build/src
make -C /tmp/wireguard-tools-build/src install

rm -rf /tmp/wireguard-tools-build

# start and autostart wg (only when a tunnel config exists)
if [ -f "$WG_CONF" ]; then
    wg-quick up "$WG_IFACE"
    systemctl enable "wg-quick@$WG_IFACE"
fi