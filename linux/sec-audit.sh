#!/bin/bash

REPORT_DIR="../reports"
REPORT="$REPORT_DIR/linux-report.txt"

if [ ! -d "$REPORT_DIR" ]; then
	mkdir -p "$REPORT_DIR"
fi

WARNING_COUNT=0
CRITICAL_COUNT=0

echo "Running the security audit..."
echo "Report saving to $REPORT"
echo ""

echo "[1/6] Collecting system information..."
HOSTNAME=$(hostname)
USER_NAME=$(whoami)
KERNAL_VERSION=$(uname -r)
OS_INFO=$(grep PRETTY_NAME /etc/os-release)
IP_INFO=$(ip a | grep inet)

echo "[2/6] Checking open network ports..."
OPEN_PORTS=$(ss -tuln)

echo "[3/6] Detecting privileged users..."
PRIV_USERS=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
PRIV_USERS_COUNT=$(awk -F: '$3 == 0 {count++} END {print count+0}' /etc/passwd)

echo "[4/6] Scanning for world-writable files..."
WORLD_WRITABLES=$(find / -xdev -type f -perm -0002 2>/dev/null | head -n 50)
WW_COUNT=$(find / -xdev -type f -perm -0002 2>/dev/null | wc -l)

echo "[5/6] Scanning for SUID binaries..."
SUID_FILES=$(find / -xdev -perm -4000 2>/dev/null | head -n 50)
SUID_COUNT=$(find / -xdev -perm -4000 2>/dev/null | wc -l)

echo "[6/6] Failed SSH login attempts..."
FAILED_SSH=$(journalctl -u ssh 2>/dev/null | grep "Failed password")
FAILED_SSH_COUNT=$(journalctl -u ssh 2>/dev/null | grep "Failed password" | wc -l)

if [ "$PRIV_USERS_COUNT" -gt 1 ]; then
	CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
fi

if [ "$WW_COUNT" -gt 0 ]; then
	WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$SUID_COUNT" -gt 0 ]; then
	WARNING_COUNT=$((WARNING_COUNT + 1))
fi

if [ "$FAILED_SSH_COUNT" -gt 0 ]; then
	WARNING_COUNT=$((WARNING_COUNT + 1))
fi


{
echo "==== SECURITY AUDIT ===="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
echo "System Information"
echo "------------------"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Kernel Version: $KERNEL_VERSION"
echo "Operating System: $OS_INFO"

echo ""
echo "IP Addresses"
echo "------------"
echo "$IP_INFO"

echo ""
echo "Open Network Ports"
echo "------------------"
echo "$OPEN_PORTS"

echo ""
echo "Privileged Users"
echo "----------------"
echo "$PRIV_USERS"

echo ""
echo "World Writable Files"
echo "--------------------"
if [ "$WW_COUNT" -eq 0 ]; then
	echo "No world-writable files found"
else
	echo "$WORD_WRITABLES"
fi

echo ""
echo "SUID (Set User ID)  Binaries"
echo "----------"
echo "Total Found: $SUID_COUNT"
if [ "$SUID_COUNT" -eq 0 ]; then
	echo "No SUID binaries found"
else
	echo ""
	echo "First 50 results:"
	echo "$SUID_FILES"
fi

echo ""
echo "Failed SSH Login Attempts"
echo "-------------------------"
echo "Total Found: $FAILED_SSH_COUNT"
if [ "$FAILED_SSH_COUNT" -eq 0 ]; then 
	echo "No failed SSH login attempts found"
else
	echo ""
	echo "Showing last 20 result:"
	echo "$FAILED_SSH"
fi

echo ""
echo "Risk Summary"
echo "------------"
echo "Warning: $WARNING_COUNT"
echo "Critical $CRITICAL_COUNT"

} > "$REPORT"

echo ""
echo "Audit completed"
echo "Report saved to $REPORT"
