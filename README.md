# Cross-Platform Security Audit Toolkit

This project is a basic cross-platform IT security auditing tool designed to identify common system misconfigurations on both Linux and Windows systems. The toolkit uses Bash for Linux environments and PowerShell for the Windows environments to collect system security information and highlight potential security risks.

---

## Features

### Linux Security Checks
- System information and host details
- IP address enumeration
- Open network ports
- Privileged user detection
- SUID binary discovery
- World-writable file detection
- Failed SSH login attempt analysis
- Risk summary highlighting warnings and critical findings

### Windows Security Checks
- System information and host details
- IP address enumeration
- Open network ports
- Local administrator detection
- Failed login attempt detection from Windows Security logs

---

## Clone Repository
https://github.com/Nicolas-Ly/security-audit-toolkit.git

---

## Usage

### Linux Audit

Run the Bash script:
./sec-audit.sh

### Windows Audit

Run the Bash script:
./sec-audit.ps1

The audit report will be saved to the `reports/` directory.

---

## Example Security Checks

The audit tool attempts to detect common misconfigurations such as:

- Excessive user privileges
- Exposed network services
- SUID binaries that may allow privilege escalation
- World-writable files that could be abused
- Repeated failed authentication attempts
- Unauthorized administrative access

---

## Future Improvements

Possible future enhancements include:

- Automated risk scoring system
- Detection of weak file permissions
- Service misconfiguration checks
- Integration with security logging tools
- Automated remediation suggestions

---

## Technologies Used

- Bash
- PowerShell
- Linux Security Tools
- Windows Event Logging
- Git & GitHub
