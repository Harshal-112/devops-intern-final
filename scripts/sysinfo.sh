#!/usr/bin/env bash
set -euo pipefail

echo "===== System Information ====="
printf 'Current user: '
id -un
printf 'Effective UID: '
id -u
printf 'Hostname: '
hostname
printf 'Kernel release: '
uname -r
printf 'System date (UTC): '
date -u '+%Y-%m-%dT%H:%M:%SZ'

echo
echo "===== Disk Usage ====="
df -h

echo
echo "===== Memory Usage ====="
if command -v free >/dev/null 2>&1; then
    free -h
elif [ -r /proc/meminfo ]; then
    cat /proc/meminfo
else
    echo "Memory information unavailable"
fi

echo
echo "===== Docker Daemon ====="
if command -v docker >/dev/null 2>&1 &&
   docker info >/dev/null 2>&1; then
    echo "Docker daemon: running"
else
    echo "Docker daemon: unavailable"
fi
