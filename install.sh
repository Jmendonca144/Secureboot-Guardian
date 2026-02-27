#!/usr/bin/env bash

set -e

echo "===== SecureBoot Guardian Installer ====="

if [ "$EUID" -ne 0 ]; then
  echo "Run as root:"
  echo "sudo ./install.sh"
  exit 1
fi

echo "[Installer] Installing Guardian..."

chmod +x guardian.sh

cp guardian.sh /opt/secureboot/guardian.sh

mkdir -p /opt/secureboot
chmod +x /opt/secureboot/guardian.sh

echo "[Installer] Running Guardian..."

/opt/secureboot/guardian.sh

echo
echo "Installation Complete"
echo
echo "Run status with:"
echo
echo "sudo guardian"
echo
