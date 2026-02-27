# Troubleshooting

## NVIDIA Driver Not Working

Run:

sudo guardian

---

## SecureBoot Key Not Enrolled

Run:

sudo guardian


Reboot and enroll MOK.

---

## Service Not Running

Check:

systemctl status guardian.path


---

## Logs

sudo tail -f /var/log/guardian/guardian.log

