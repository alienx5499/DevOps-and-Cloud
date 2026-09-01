# Linux Fundamentals

Homework tasks and reference guides for Linux Fundamentals (SST Term 9 - DevOps & Cloud).

---

## Directory Structure

```
Linux Fundamental/
├── README.md                      # Overview and task summaries
├── 01_Soft_vs_Hard_Links.md       # Task 1: Soft vs Hard Links
├── 02_adduser_vs_useradd.md       # Task 2: adduser vs useradd
├── 03_journalctl_Guide.md         # Task 3: journalctl & systemd logs
└── 04_Linux_Command_Cheat_Sheet.md# Task 4: Linux networking cheat sheet
```

---

## Task Summaries

### [Task 1: Soft Link vs. Hard Link](./01_Soft_vs_Hard_Links.md)
- **Hard Link (`ln file link`)**: Points directly to an existing inode. Increments link count. Remains accessible if the original name is deleted. Cannot cross filesystems or link directories.
- **Soft Link (`ln -s target link`)**: Stores target path string. Has a separate inode. Breaks if the target is moved or deleted. Supports directories and cross-filesystem links.

---

### [Task 2: `adduser` vs. `useradd`](./02_adduser_vs_useradd.md)
- **`useradd`**: Native compiled binary. Non-interactive and flag-driven (`useradd -m -s /bin/bash -G sudo <user>`). Preferred for CI/CD, scripts, and Dockerfiles.
- **`adduser`**: Interactive Perl wrapper (Debian/Ubuntu). Prompts for passwords, generates home directory, and copies `/etc/skel` templates. Preferred for manual terminal use.

---

### [Task 3: `journalctl` & Systemd Logging](./03_journalctl_Guide.md)
- **Architecture**: Interfaces with `systemd-journald` to query structured binary logs indexed by unit, PID, UID, and priority.
- **Key Commands**:
  - `journalctl -u nginx.service -f` (follow service)
  - `journalctl -p err -b` (current boot errors)
  - `journalctl -b -1` (previous boot logs)
  - `sudo journalctl --vacuum-size=200M` (reclaim disk space)

---

### [Task 4: Linux Networking & `ip` Cheat Sheet](./04_Linux_Command_Cheat_Sheet.md)
- **`ip link`**: Interface state (`up`/`down`), MTU, promiscuous mode.
- **`ip addr`**: IP address assignment, secondary aliases, and flushes.
- **`ip route`**: Default gateways, static routes, and lookup tests.
- **`ip neigh`**: ARP cache management and static MAC bindings.
- **`ip maddr`**: Multicast link-layer subscriptions.
- **`ss`**: Socket statistics and listening port inspection.
- **`arping` & `ethtool`**: Layer 2 ping, duplicate IP check, and NIC diagnostics.
- **Migration**: Complete `net-tools` (`ifconfig`, `netstat`, `route`, `arp`) to `iproute2` mapping.
