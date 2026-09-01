# `adduser` vs. `useradd`

## 1. Overview

<img src="https://github.com/user-attachments/assets/62120137-2171-40d1-bf02-2ad4485d023f" alt="adduser vs useradd Architecture" width="100%" />

- **`adduser`**: High-level interactive Perl wrapper (Debian/Ubuntu). Interactively sets up password, creates home directory, and copies `/etc/skel` files. Best for manual terminal use.
- **`useradd`**: Native compiled C binary (all distros). Non-interactive, flag-driven. Best for automation, shell scripts, and Dockerfiles.

---

## 2. Comparison Table

| Feature | `adduser` | `useradd` |
| :--- | :--- | :--- |
| Type | Perl script wrapper | Compiled binary |
| Mode | Interactive prompts | Non-interactive (flags) |
| Home Dir | Auto-creates `/home/<user>` | Needs `-m` flag |
| Skeleton Dotfiles | Auto-copies `/etc/skel` | Needs `-m` flag |
| Password | Prompts immediately | Account locked until `passwd` runs |
| Main Use | Terminal administration | Automation & Dockerfiles |

---

## 3. Practical Usage

### Create user interactively (Ubuntu/Debian):
```bash
sudo adduser devops_alex
```

### Create user in scripts / Dockerfiles:
```bash
sudo useradd -m -s /bin/bash -G sudo devops_sam
echo "devops_sam:Password123!" | sudo chpasswd
```

### Verify user:
```bash
id devops_alex
grep "devops_" /etc/passwd
```

### Delete user:
```bash
sudo deluser --remove-home devops_alex  # Debian/Ubuntu
sudo userdel -r devops_sam             # Standard
```

---

## 4. Key System Files

- `/etc/passwd`: User account definitions (UID, GID, home, shell)
- `/etc/shadow`: Encrypted password hashes
- `/etc/group`: Group memberships
- `/etc/skel/`: Default dotfiles (`.bashrc`, `.profile`) copied to new home directories

---

## 5. Interview Questions

**Q1: Why use `useradd` in CI/CD and Dockerfiles over `adduser`?**
- `useradd` is non-interactive and does not block waiting for standard input. It is also standard across all distributions (Ubuntu, RHEL, Alpine), whereas `adduser` is distro-dependent.

**Q2: What happens if you run `useradd testuser` without flags?**
- The account is created in `/etc/passwd` and `/etc/shadow`, but no home folder is created, no skeleton dotfiles are copied, and the account remains locked until a password is assigned.
