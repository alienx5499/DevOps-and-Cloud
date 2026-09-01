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
