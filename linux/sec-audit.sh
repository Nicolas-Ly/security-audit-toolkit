
#!/bin/bash

REPORT_DIR="../reports"
REPORT="$REPORT_DIR/linux-report.txt"

if [ ! -d "$REPORT_DIR" ]; then
	mkdir -p "$REPORT_DIR"
fi

RISK_SCORE=0

echo "Running the security audit..."
echo "Report saving to $REPORT"
echo ""

echo "[1/9] Collecting system information..."
HOSTNAME=$(hostname)
USER_NAME=$(whoami)
KERNEL_VERSION=$(uname -r)
OS_INFO=$(grep PRETTY_NAME /etc/os-release)
IP_INFO=$(ip a | grep inet)

echo "[2/9] Checking open network ports..."
OPEN_PORTS=$(ss -tuln)

echo "[3/9] Detecting privileged users..."
PRIV_USERS=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
PRIV_USERS_COUNT=$(awk -F: '$3 == 0 {count++} END {print count+0}' /etc/passwd)

echo "[4/9] Scanning for world-writable files..."
WORLD_WRITABLES=$(find / -xdev -type f -perm -0002 2>/dev/null | head -n 50)
WW_COUNT=$(find / -xdev -type f -perm -0002 2>/dev/null | wc -l)

#-----

echo "[5/9] Scanning for world-writable directories..."
WORLD_WRITABLE_DIR=$(find / -xdev -type d -perm -0002 2>/dev/null | head -n 50)
WW_DIR_COUNT=$(find / -xdev -type d -perm -0002 2>/dev/null | wc -l)

echo "[6/9] Scanning for permission 0777 files..."
PERM_777_FILES=$(find / -xdev -type f -perm 0777 2>/dev/null | head -n 50)
PERM_777_COUNT=$(find / -xdev -type f -perm 0777 2>/dev/null | wc -l)

echo "[7/9] Scanning for weak file permissions..."
ETC_WEAK_FILES=$(find /etc -type f -perm -0002 2>/dev/null | head -n 50)
ETC_WEAK_COUNT=$(find /etc -type f -perm -0002 2>/dev/null | wc -l)

#----

echo "[8/9] Scanning for SUID binaries..."
SUID_FILES=$(find / -xdev -perm -4000 2>/dev/null | head -n 50)
SUID_COUNT=$(find / -xdev -perm -4000 2>/dev/null | wc -l)

echo "[9/9] Failed SSH login attempts..."
FAILED_SSH=$(journalctl -u ssh 2>/dev/null | grep "Failed password")
FAILED_SSH_COUNT=$(journalctl -u ssh 2>/dev/null | grep "Failed password" | wc -l)

if [ "$PRIV_USERS_COUNT" -gt 1 ]; then
	RISK_SCORE=$((RISK_SCORE + 3))
fi

if [ "$WW_COUNT" -gt 0 ]; then
	RISK_SCORE=$((RISK_SCORE + 3))
fi

if [ "$WW_DIR_COUNT" -gt 0 ]; then
	RISK_SCORE=$((RISK_SCORE + 2))
fi

if [ "$PERM_777_COUNT" -gt 0 ]; then
        RISK_SCORE=$((RISK_SCORE + 2))
fi

if [ "$ETC_WEAK_COUNT" -gt 0 ]; then
        RISK_SCORE=$((RISK_SCORE + 3))
fi

if [ "$SUID_COUNT" -gt 20 ]; then
	RISK_SCORE=$((RISK_SCORE + 2))
fi

if [ "$FAILED_SSH_COUNT" -gt 10 ]; then
	RISK_SCORE=$((RISK_SCORE + 2))
fi


# Risk calculation ------------------

if [ "$RISK_SCORE"  -le 2 ]; then
	RISK_LEVEL="***LOW***"
elif [ "$RISK_SCORE" -le 5 ]; then
	RISK_LEVEL="***MEDIUM***"
else
	RISK_LEVEL="***HIGH***"
fi



{
echo "==== SECURITY AUDIT ===="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"

echo ""
echo "   System Information"
echo "------------------------"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Kernel Version: $KERNEL_VERSION"
echo "Operating System: $OS_INFO"

echo ""
echo "   IP Addresses"
echo "------------------"
echo "$IP_INFO"

echo ""
echo "   Open Network Ports"
echo "------------------------"
echo "$OPEN_PORTS"

echo ""
echo "   Privileged Users"
echo "----------------------"
echo "Privileged Users Found: $PRIV_USERS_COUNT"
echo "$PRIV_USERS"


echo ""
echo "   World Writable Files"
echo "--------------------------"
if [ "$WW_COUNT" -eq 0 ]; then
	echo "No world-writable files found"
else
	echo "Total Found: $WW_COUNT"
	echo "$WORLD_WRITABLES"
fi

echo ""
echo "   World Writable Directories"
echo "--------------------------------"
if [ "$WW_DIR_COUNT" -eq 0 ]; then
        echo "No world-writable directories found"
else
        echo "Total Found: $WW_DIR_COUNT"
        echo "$WORLD_WRITABLE_DIR"
fi

echo ""
echo "   Permission 0777 Files"
echo "---------------------------"
if [ "$PERM_777_COUNT" -eq 0 ]; then
        echo "No 0777 files found"
else
        echo "Total Found: $PERM_777_COUNT"
        echo "$PERM_777_FILES"
fi

echo ""
echo "   Weak ETC Files"
echo "--------------------"
if [ "$ETC_WEAK_COUNT" -eq 0 ]; then
        echo "No ETC files found"
else
        echo "Total Found: $ETC_WEAK_COUNT"
        echo "$ETC_WEAK_FILES"
fi

echo ""
echo "   SUID (Set User ID)  Binaries"
echo "----------------------------------"
echo "Total Found: $SUID_COUNT"
if [ "$SUID_COUNT" -eq 0 ]; then
	echo "No SUID binaries found"
else
	echo ""
	echo "First 50 results:"
	echo "$SUID_FILES"
fi

echo ""
echo "   Failed SSH Login Attempts"
echo "-------------------------------"
echo "Total Found: $FAILED_SSH_COUNT"
if [ "$FAILED_SSH_COUNT" -eq 0 ]; then
	echo "No failed SSH login attempts found"
else
	echo ""
	echo "$FAILED_SSH"
fi

echo ""
echo "   Risk Summary   "
echo "------------------"
echo "Risk Score: $RISK_SCORE"
echo "Risk Level: $RISK_LEVEL"

echo ""
echo "   Remediation   "
echo "-----------------"
if [ "$PRIV_USERS_COUNT" -gt 1 ]; then
	echo "- Review accounts with UID 0 and remove any unnecessary privileged users."
fi

if [ "$WW_COUNT" -gt 0 ]; then
	echo "- Review world-writable files and restrict permissions using chmod when appropriate"
fi

if [ "$SUID_COUNT" -gt 20 ]; then
	echo "- Review set user ID binaries and confirm each privileged executable is expected"
fi

if [ "$WW_DIR_COUNT" -gt 0 ]; then
	echo "- Review world-writable directories and restrict access where unnecessary."
fi

if [ "$PERM_777_COUNT" -gt 0 ]; then
	echo "- Review files with 0777 permissions and apply more restrictive permissions."
fi

if [ "$ETC_WEAK_COUNT" -gt 0 ]; then
	echo "- Review weak permissions in /etc because configuration files should not be world-writable."
fi

if [ "$FAILED_SSH_COUNT" -gt 10 ]; then
	echo "- Investigate repeated failed SSH login attempts and consider hardening SSH access."
fi

} > "$REPORT"

echo ""
echo "Audit completed"
echo "Report saved to $REPORT"
