$Report = "../reports/windows-report.txt"

Write-Host "Starting Windows Security Audit..."
Write-Host "The report will be saved to $Report"
Write-Host ""

Write-Host "[1/5] Collecting system information"
$Hostname = $env:COMPUTERNAME
$User = "$env:USERDOMAIN\$env:USERNAME"
$OS = (Get-CimInstance Win32_OperatingSystem).Caption

Write-Host "[2/5] Collecting IP addresses"
$IPInfo = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" }

Write-Host "[3/5] Checking listening network ports"
$OpenPorts = Get-NetTCPConnection -State Listen

Write-Host "[4/5] Checking local Administrators"
$Admins = Get-LocalGroupMember -Group "Administrators"

Write-Host "[5/5] Checking failed login attempts"
$FailedLogons = Get-WinEvent -FilterHashtable @{LogName = 'Security'; Id=4625} -MaxEvents 20

@"
===== WINDOWS SECURITY AUDIT =====
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

System Information
------------------
Hostname: $Hostname
User: $User
Operating System: $OS

IP Addresses
------------
$($IPInfo | Out-String)

Open Network Ports
------------------
$($OpenPorts | Out-String)

Administrators
--------------
$($Admins | Out-String)

Failed Login Attempts
---------------------
$($FailedLogons | Out-String)

"@ | Set-Content $Report


Write-Host ""
Write-Host "Windows Security Audit Complete"
Write-Host "Report saved to $Report"

