#!/usr/bin/env bash
set -euo pipefail

BR="${1:?bridge name (e.g. br-ex)}"
IFACE="${2:?NIC to enslave (e.g. enp6s0)}"

# 1) Create bridge if missing
if ! ip link show "$BR" &>/dev/null; then
  ip link add "$BR" type bridge
fi

# 2) Capture any IPs on the NIC to move them to the bridge
IPV4=$(ip -4 addr show dev "$IFACE" | awk '/inet /{print $2}' || true)
IPV6=$(ip -6 addr show dev "$IFACE" | awk '/inet6 /{print $2}' || true)

# 3) Enslave + bring up
ip link set "$IFACE" down || true
ip link set "$IFACE" master "$BR" || true
ip link set "$BR" up
ip link set "$IFACE" up

# 4) Move L3 addresses from NIC -> bridge (idempotent)
if [[ -n "${IPV4:-}" ]]; then
  ip addr del "$IPV4" dev "$IFACE" || true
  ip addr add "$IPV4" dev "$BR" || true
fi
if [[ -n "${IPV6:-}" ]]; then
  ip -6 addr del "$IPV6" dev "$IFACE" || true
  ip -6 addr add "$IPV6" dev "$BR" || true
fi
