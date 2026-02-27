#!/usr/bin/env bash

echo "===== Removing SecureBoot Guardian ====="

sudo systemctl disable guardian.service 2>/dev/null || true
sudo systemctl disable guardian.path 2>/dev/null || true

sudo rm -f /etc/systemd/system/guardian.service
sudo rm -f /etc/systemd/system/guardian.path

sudo rm -f /usr/local/bin/guardian

sudo rm -rf /opt/secureboot

sudo systemctl daemon-reload

echo "Guardian removed"
