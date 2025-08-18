#!/usr/bin/env bash
set -euo pipefail
BR="${1:?bridge name}"; IFACE="${2:?external NIC}"

# Create bridge if missing
ip link show "$BR" >/dev/null 2>&1 || ip link add "$BR" type bridge

# Capture any IPs on the NIC to move them
IPV4=$(ip -4 addr show dev "$IFACE" | awk '/inet /{print $2}' || true)
IPV6=$(ip -6 addr show dev "$IFACE" | awk '/inet6 /{print $2}' || true)

# Enslave and bring up
ip link set "$IFACE" down || true
ip link set "$IFACE" master "$BR" || true
ip link set "$BR" up
ip link set "$IFACE" up

# Move addresses from NIC to bridge (avoid networkd re-asserting on NIC)
if [[ -n "$IPV4" ]]; then
  ip addr del "$IPV4" dev "$IFACE" || true
  ip addr add "$IPV4" dev "$BR" || true
fi
if [[ -n "$IPV6" ]]; then
  ip -6 addr del "$IPV6" dev "$IFACE" || true
  ip -6 addr add "$IPV6" dev "$BR" || true
fi
