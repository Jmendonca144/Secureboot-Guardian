# Architecture

SecureBoot Guardian consists of:

- guardian.sh (core engine)
- guardian.service (systemd runner)
- guardian.path (kernel monitor)
- guardian command (status tool)

Flow:

Kernel Update
  ↓
guardian.path detects change
  ↓
guardian.service runs
  ↓
guardian.sh executes
  ↓
DKMS rebuild
  ↓
Module signing
  ↓
SecureBoot verification
  ↓
NVIDIA verification
