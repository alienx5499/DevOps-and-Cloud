# Linux Networking & `ip` Cheat Sheet

Reference for `iproute2` (`ip`, `ss`) and core Linux networking utilities (`arping`, `ethtool`).

---

## 1. Interface & Link Management (`ip link`)

| Task | Command |
| :--- | :--- |
| Show all interfaces | `ip link` |
| Show specific interface | `ip link show dev em1` |
| Interface statistics | `ip -s link` |
| Bring interface up | `ip link set em1 up` |
| Bring interface down | `ip link set em1 down` |
| Set MTU size | `ip link set em1 mtu 9000` |
| Promiscuous mode on/off | `ip link set em1 promisc on` / `off` |

---

## 2. Address Management (`ip addr`)

| Task | Command |
| :--- | :--- |
| Show all IP addresses | `ip addr` |
| Show interface IP | `ip addr show dev em1` |
| Add IP address | `ip addr add 192.168.1.1/24 dev em1` |
| Add secondary IP | `ip addr add 192.168.1.2/24 dev em1` |
| Delete IP address | `ip addr del 192.168.1.1/24 dev em1` |
| Flush all IPs on device | `ip addr flush dev em1` |

---

## 3. Routing Table (`ip route`)

| Task | Command |
| :--- | :--- |
| Show routing table | `ip route` |
| Add default gateway | `ip route add default via 192.168.1.1 dev em1` |
| Add route via gateway | `ip route add 192.168.1.0/24 via 192.168.1.1` |
| Add route on device | `ip route add 192.168.1.0/24 dev em1` |
| Delete route | `ip route delete 192.168.1.0/24 via 192.168.1.1` |
| Replace route | `ip route replace 192.168.1.0/24 dev em1` |
| Route lookup for IP | `ip route get 192.168.1.5` |

---

## 4. ARP / Neighbor Cache (`ip neigh`)

| Task | Command |
| :--- | :--- |
| Show ARP cache | `ip neigh` |
| Show ARP for device | `ip neigh show dev em1` |
| Add static ARP entry | `ip neigh add 192.168.1.1 lladdr 1:2:3:4:5:6 dev em1` |
| Delete ARP entry | `ip neigh del 192.168.1.1 dev em1` |
| Replace ARP entry | `ip neigh replace 192.168.1.1 lladdr 1:2:3:4:5:6 dev em1` |

---

## 5. Multicast (`ip maddr`)

| Task | Command |
| :--- | :--- |
| Show multicast addresses | `ip maddr` |
| Show for device | `ip maddr show dev em1` |
| Add multicast address | `ip maddr add 33:33:00:00:00:01 dev em1` |
| Delete multicast address | `ip maddr del 33:33:00:00:00:01 dev em1` |

---

## 6. Socket Statistics (`ss`)

| Task | Command |
| :--- | :--- |
| All sockets | `ss -a` |
| Listening sockets | `ss -l` |
| TCP sockets only | `ss -t` |
| Numeric (no DNS resolution) | `ss -n` |
| Show PID and process name | `ss -p` |
| Standard listening check | `ss -tulnp` |

---

## 7. Diagnostics (`arping`, `ethtool`)

### `arping` (Layer 2 reachability):
```bash
arping -I eth0 192.168.1.1       # Ping IP via ARP
arping -D -I eth0 192.168.1.1    # Duplicate address detection
```

### `ethtool` (NIC diagnostics):
```bash
ethtool eth0                     # Link speed and duplex
ethtool -i eth0                  # Driver info
ethtool -S eth0                  # Hardware error counters
ethtool -p eth0                  # Blink physical port LED
```

---

## 8. Migration: `net-tools` to `iproute2`

| `net-tools` (Legacy) | `iproute2` (Modern) |
| :--- | :--- |
| `ifconfig -a` | `ip addr` |
| `ifconfig eth0 down / up` | `ip link set eth0 down / up` |
| `ifconfig eth0 192.168.1.1` | `ip addr add 192.168.1.1/24 dev eth0` |
| `ifconfig eth0 mtu 9000` | `ip link set eth0 mtu 9000` |
| `arp -a` | `ip neigh` |
| `arp -s 192.168.1.1 1:2:3:4:5:6` | `ip neigh add 192.168.1.1 lladdr 1:2:3:4:5:6 dev eth1` |
| `route` | `ip route` |
| `route add default gw 192.168.1.1` | `ip route add default via 192.168.1.1` |
| `netstat` | `ss` |
| `netstat -tulnp` | `ss -tulnp` |
| `netstat -g` | `ip maddr` |
