#!/bin/bash

set -e

VERSION="v11"
KEYDIR="/root/.secureboot"
LOGDIR="/var/log/guardian"
LOGFILE="$LOGDIR/guardian.log"

mkdir -p $LOGDIR
touch $LOGFILE

log() {
 echo "[Guardian] $1" | tee -a $LOGFILE
}

echo "===== Secure Boot Guardian $VERSION ====="

############################
# Cleanup Previous Versions
############################

log "Cleaning old installs..."

rm -f /usr/local/bin/guardian
rm -f /etc/systemd/system/guardian.service
rm -f /etc/systemd/system/guardian.path

systemctl daemon-reexec >/dev/null 2>&1 || true


############################
# Install Dependencies
############################

log "Installing dependencies..."

apt-get update -y >/dev/null

apt-get install -y \
mokutil \
openssl \
dkms \
build-essential \
libelf-dev \
zstd \
linux-headers-$(uname -r) >/dev/null


############################
# SecureBoot Key Setup
############################

mkdir -p $KEYDIR

if [ ! -f "$KEYDIR/MOK.key" ] || [ ! -f "$KEYDIR/MOK.der" ]; then

log "Generating SecureBoot keys..."

openssl req -new -x509 -newkey rsa:2048 \
-keyout $KEYDIR/MOK.key \
-outform DER \
-out $KEYDIR/MOK.der \
-nodes \
-days 36500 \
-subj "/CN=SecureBootGuardian/"

fi


############################
# Verify Keypair Match
############################

log "Verifying SecureBoot keypair..."

if ! openssl x509 -noout -modulus -in $KEYDIR/MOK.der 2>/dev/null | sha256sum \
| diff -q - <(openssl rsa -noout -modulus -in $KEYDIR/MOK.key | sha256sum) >/dev/null
then

log "Keypair mismatch detected - regenerating..."

rm -rf $KEYDIR

mkdir -p $KEYDIR

openssl req -new -x509 -newkey rsa:2048 \
-keyout $KEYDIR/MOK.key \
-outform DER \
-out $KEYDIR/MOK.der \
-nodes \
-days 36500 \
-subj "/CN=SecureBootGuardian/"

mokutil --import $KEYDIR/MOK.der

log "Reboot required for MOK enrollment"

exit 0

fi


############################
# MOK Enrollment Check
############################

log "Checking MOK enrollment..."

if ! mokutil --test-key $KEYDIR/MOK.der 2>/dev/null | grep -q "already enrolled"; then

log "MOK key NOT enrolled - reboot required"

mokutil --import $KEYDIR/MOK.der

exit 0

fi


############################
# DKMS Build
############################

log "Building DKMS modules..."

dkms autoinstall || true


############################
# Module Signing
############################

log "Signing modules..."

SIGNFILE="/usr/src/linux-headers-$(uname -r)/scripts/sign-file"

MODDIR="/lib/modules/$(uname -r)/updates/dkms"

if [ -d "$MODDIR" ]; then

for mod in $MODDIR/*.ko*; do

[ -e "$mod" ] || continue

zstd -df "$mod" -o "${mod%.zst}" 2>/dev/null || true

KO="${mod%.zst}"

$SIGNFILE sha256 \
$KEYDIR/MOK.key \
$KEYDIR/MOK.der \
"$KO" || true

zstd -f "$KO"

done

fi


############################
# depmod
############################

log "Running depmod..."

depmod -a


############################
# NVIDIA Health Check
############################

log "Checking NVIDIA..."

if ! nvidia-smi >/dev/null 2>&1; then

log "NVIDIA failure detected"

log "Rebuilding DKMS..."

dkms autoinstall || true

log "Resigning modules..."

for mod in $MODDIR/*.ko*; do

[ -e "$mod" ] || continue

zstd -df "$mod" -o "${mod%.zst}" 2>/dev/null || true

KO="${mod%.zst}"

$SIGNFILE sha256 \
$KEYDIR/MOK.key \
$KEYDIR/MOK.der \
"$KO" || true

zstd -f "$KO"

done

depmod -a

log "Reloading NVIDIA..."

modprobe -r nvidia 2>/dev/null || true
modprobe nvidia || true

fi


############################
# Install Status Command
############################

log "Installing guardian command..."

cat << 'EOF' > /usr/local/bin/guardian
#!/bin/bash

KEY="/root/.secureboot/MOK.der"

echo "===== Guardian Status ====="

echo
echo "SecureBoot:"
mokutil --sb-state

echo
echo "Kernel:"
uname -r

echo
echo "Last Known Good Kernel:"
uname -r

echo
echo "SecureBoot Key:"

if sudo mokutil --test-key $KEY 2>/dev/null | grep -q "already enrolled"; then
 echo "ENROLLED"
else
 echo "NOT ENROLLED"
fi

echo
echo "NVIDIA:"
nvidia-smi 2>/dev/null || echo "Failed"

echo
echo "Logs:"
tail -n 20 /var/log/guardian/guardian.log 2>/dev/null

EOF

chmod +x /usr/local/bin/guardian


############################
# Install systemd service
############################

log "Installing service..."

cat << EOF > /etc/systemd/system/guardian.service
[Unit]
Description=SecureBoot Guardian
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/opt/secureboot/guardian.sh
EOF


cat << EOF > /etc/systemd/system/guardian.path
[Unit]
Description=Guardian Kernel Monitor

[Path]
PathChanged=/lib/modules
Unit=guardian.service

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable guardian.path >/dev/null
systemctl start guardian.path >/dev/null


############################
# Final Health Check
############################

log "Final health check..."

if nvidia-smi >/dev/null 2>&1; then
log "System Healthy"
else
log "System Needs Attention"
fi


log "Guardian installation complete"

echo
echo "DONE"
