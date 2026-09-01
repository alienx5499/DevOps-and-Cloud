# `journalctl` & Systemd Logging

## 1. Overview

`journalctl` queries binary logs collected by `systemd-journald`.

<img src="https://github.com/user-attachments/assets/f7944d23-4495-4856-b628-900deb8f40b9" alt="journalctl Architecture" width="100%" />

### Key Advantages over `/var/log/syslog`:
- **Single daemon**: Captures kernel messages, service `stdout`/`stderr`, and syslog.
- **Indexed**: Fast searches by unit, timestamp, PID, or priority.
- **Tamper-resistant**: Stored in binary format.

---

## 2. Essential Commands

| Task | Command |
| :--- | :--- |
| View all logs | `journalctl` |
| Follow live logs | `journalctl -f` |
| Specific service | `journalctl -u nginx.service` |
| Follow service | `journalctl -u nginx.service -f` |
| Last N lines | `journalctl -n 50` |
| Current boot | `journalctl -b` |
| Previous boot | `journalctl -b -1` |
| Kernel logs | `journalctl -k` |
| Time window | `journalctl --since "1 hour ago"` |
| Specific dates | `journalctl --since "2026-09-01" --until "2026-09-02 12:00"` |
| Error level and above | `journalctl -p err` |
| JSON output | `journalctl -u nginx -o json-pretty` |
| Check disk usage | `journalctl --disk-usage` |
| Vacuum logs | `sudo journalctl --vacuum-size=200M` |

---

## 3. Troubleshooting Workflow

<img src="https://github.com/user-attachments/assets/ef0ea027-c4fe-4c48-b7cc-c78908b76ee1" alt="Troubleshooting Workflow" width="100%" />

```bash
# 1. Check unit status:
systemctl status nginx.service

# 2. View recent logs from the unit:
journalctl -u nginx.service -b -e --no-pager

# 3. Check for system-wide errors in failure timeframe:
journalctl -p err --since "10 min ago"

# 4. Validate configuration and restart:
nginx -t
sudo systemctl restart nginx
```

---

## 4. Interview Questions

**Q1: How does `journalctl` differ from `/var/log/syslog`?**
- `syslog` is flat text written by rsyslog. `journalctl` queries indexed binary logs from `systemd-journald`, allowing fast filtering by service (`-u`), boot (`-b`), and time without parsing text with `grep`/`awk`.

**Q2: How do you check why a server rebooted unexpectedly?**
- List boots with `journalctl --list-boots`, then view errors from the previous boot: `journalctl -b -1 -p err`.

**Q3: How do you clean up disk space used by journal logs?**
```bash
journalctl --disk-usage
sudo journalctl --vacuum-size=100M
```
