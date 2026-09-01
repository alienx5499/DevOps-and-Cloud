# Shell Scripting: System Information Script

A bash script that prints system information, disk usage, and running processes, takes user input, creates a directory and file, and saves the process list.

<img src="https://github.com/user-attachments/assets/b22aff6e-1ca2-4cb3-a254-d68c5a868146" alt="System Information Script Workflow" width="100%" />

---

## Script: `system_info.sh`

```bash
#!/bin/bash

# System Information Script

current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "Date: $current_date"
echo "Hostname: $host_name"
echo "User: $user_name"

echo ""
echo "Disk Usage:"
df -h

echo ""
echo "Running Processes:"
ps aux

echo ""
read -p "Enter directory name: " dir_name
read -p "Enter file name: " file_name

mkdir -p "$dir_name"
touch "$dir_name/$file_name"

ps aux > "$dir_name/$file_name"
echo "Process list saved to $dir_name/$file_name"
```

---

## How to Run

1. Make the script executable:
   ```bash
   chmod +x system_info.sh
   ```

2. Run the script:
   ```bash
   ./system_info.sh
   ```

---

## Sample Terminal Output

```text
Date: Thu Sep  3 00:07:21 IST 2026
Hostname: PRABALs-MacBook-Max.local
User: prabalpatra

Disk Usage:
Filesystem       Size    Used   Avail Capacity Mounted on
/dev/disk3s1s1  1.8Ti    12Gi   1.4Ti     1%   /
/dev/disk3s5    1.8Ti   440Gi   1.4Ti    25%   /System/Volumes/Data

Running Processes:
USER          PID  %CPU %MEM   COMMAND
root            1   0.0  0.1   /sbin/launchd
prabalpatra   609   2.4  0.4   /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer
prabalpatra  5983  21.5  0.6   /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
prabalpatra 13878   5.4  2.3   /Applications/Antigravity IDE.app/Contents/MacOS/Antigravity IDE

Enter directory name: logs
Enter file name: processes.txt
Process list saved to logs/processes.txt
```

---

## Commands Used

- `date`: Prints current date and time.
- `hostname`: Prints system host name.
- `whoami`: Prints active user name.
- `df -h`: Prints disk space usage in human-readable format.
- `ps aux`: Lists running processes.
- `read -p`: Takes interactive user input from the terminal into variables.
- `mkdir -p`: Creates the target directory.
- `touch`: Creates the target file.
- `>`: Redirects standard output from `ps aux` to the file.
