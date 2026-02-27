# Secureboot-Guardian
A service to manage secureboot on kubuntu 25 

SecureBoot Guardian is an automated Secure Boot and NVIDIA driver recovery system for Linux.

It automatically rebuilds, signs, and validates NVIDIA kernel modules after kernel updates to ensure the NVIDIA driver continues working with **Secure Boot enabled**.

This tool was designed and tested on **Kubuntu with Secure Boot + NVIDIA 590-open drivers**, but should work on most Ubuntu-based systems.

---

# Purpose

This script was designed to allow me to enable Secure Boot on my system.

I am sharing this script to help others who want to do the same to theirs.

**I will not accept liability for any issues that arise from this script if you decide to use it.**

Use at your own risk.

That being said I am open to suggestions for improvements that can be made.

---

# Features

- Automatic SecureBoot key generation
- Automatic MOK enrollment
- DKMS rebuild automation
- NVIDIA module signing
- SecureBoot verification
- NVIDIA driver health checks
- Automatic driver recovery
- Kernel update detection
- Self-healing service
- Status command
- Logging system
- Automatic cleanup of old installations

---

# How It Works

SecureBoot Guardian runs as a background system service.

When a kernel update or module change occurs:

1. Kernel modules are detected as changed
2. Guardian service runs automatically
3. DKMS modules are rebuilt
4. Modules are signed for Secure Boot
5. SecureBoot keys are verified
6. NVIDIA driver is tested
7. If broken → automatic repair is attempted
8. Status is logged

---

# Architecture

Kernel Update
↓
guardian.path detects change
↓
guardian.service runs
↓
DKMS rebuild
↓
Module signing
↓
SecureBoot validation
↓
NVIDIA verification
↓
Self-heal if needed


---

# Installation

## Step 1 — Clone Repository
git clone https://github.com/Jmendonca144/Secureboot-Guardian.git
cd secureboot-guardian



---

## Step 2 — Install Guardian
sudo chmod +x guardian.sh
sudo ./guardian.sh


---

## Step 3 — Reboot (If Prompted)

If SecureBoot keys need enrollment, you will see:
-Reboot required for MOK enrollment


After reboot:

- Select **Enroll MOK**
- Enter password
- Reboot again

---

# Usage

## Check System Status
sudo guardian

Example output:
===== Guardian Status =====

SecureBoot:
SecureBoot enabled

Kernel:
6.18.x

SecureBoot Key:
ENROLLED

NVIDIA:
Driver Version: 590.xx

Logs:
System Healthy



---

# What The Script Does (Step-by-Step)

## 1. Cleans Previous Installations

Removes:
/usr/local/bin/guardian
/etc/systemd/system/guardian.service
/etc/systemd/system/guardian.path


Prevents conflicts with older versions.

---

## 2. Installs Dependencies

Installs required packages:

- mokutil
- openssl
- dkms
- build-essential
- libelf-dev
- zstd
- linux-headers

---

## 3. Creates SecureBoot Keys

Generates:
/root/.secureboot/MOK.key
/root/.secureboot/MOK.der


Used for signing kernel modules.

---

## 4. Verifies SecureBoot Keypair

Ensures:
MOK.key matches MOK.der


If mismatch detected:

- Keys regenerated
- MOK enrollment requested

---

## 5. Verifies MOK Enrollment

Checks:
mokutil --test-key


If not enrolled:

- Automatically imports key
- Requests reboot

---

## 6. Builds DKMS Modules

Runs:
dkms autoinstall


Ensures drivers match the current kernel.

---

## 7. Signs Kernel Modules

Signs:
/lib/modules/<kernel>/updates/dkms/*.ko.zst


Using:
scripts/sign-file


Required for Secure Boot.

---

## 8. Runs depmod

Updates module dependency database.

depmod -a


---

## 9. NVIDIA Health Check

Runs:
nvidia-smi


If failure detected:

- DKMS rebuild
- Modules resigned
- NVIDIA reloaded

---

## 10. Installs Status Command

Creates:
/usr/local/bin/guardian


Command:
sudo guardian


Displays:

- SecureBoot status
- Kernel version
- Key enrollment status
- NVIDIA status
- Logs

---

## 11. Installs Automatic Service

Creates:
guardian.service
guardian.path


These automatically trigger Guardian when kernel modules change.

---

## 12. Logging

Logs stored in:
/var/log/guardian/guardian.log


View logs:
sudo guardian
or
sudo tail -f /var/log/guardian/guardian.log


---

# Requirements

- Ubuntu / Kubuntu / Debian-based distro
- Secure Boot enabled
- NVIDIA GPU
- DKMS drivers
- Root access

---

# Tested Hardware

- NVIDIA RTX 5070 Ti
- NVIDIA 590-open drivers
- Kernel 6.18+

---

# Troubleshooting

## NVIDIA Not Working

Run:
sudo guardian


Guardian will attempt automatic repair.

---

## SecureBoot Key Not Enrolled

Run:
sudo guardian


Then reboot and enroll the MOK key.

---

## Check Service
systemctl status guardian.path


---

# Uninstall

sudo rm /usr/local/bin/guardian

sudo rm /etc/systemd/system/guardian.service
sudo rm /etc/systemd/system/guardian.path

sudo systemctl daemon-reload


---

# Safety Notice

This script modifies:

- Kernel modules
- DKMS builds
- SecureBoot keys
- System services

Use at your own risk.


---

# Author: Joseph Mendonca

Created for enabling Secure Boot with NVIDIA on Linux.

Shared to help others achieve the same.
