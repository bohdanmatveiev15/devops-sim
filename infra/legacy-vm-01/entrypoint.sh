#!/bin/bash
set -euo pipefail

# Left behind by the base image: it blocks logins for everyone except root.
rm -f /run/nologin /var/run/nologin

install -m 600 /etc/finsim/hostkeys/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
install -d -o bohdan -g bohdan -m 700 /home/bohdan/.ssh
install -o bohdan -g bohdan -m 600 /etc/finsim/authorized_key.pub /home/bohdan/.ssh/authorized_keys

printf 'ops-admin:%s\n' "$(cat /etc/finsim/secrets/ops-admin.txt)" | chpasswd

if [ ! -f /opt/reports/etc/settings.ini ]; then
    python3 - <<'PY'
import os
with open("/usr/local/share/reports/settings.ini.tmpl") as src:
    text = src.read()
for key, value in (
    ("@HOST@", "REPORTS_DB_HOST"),
    ("@PORT@", "REPORTS_DB_PORT"),
    ("@NAME@", "REPORTS_DB_NAME"),
    ("@USER@", "REPORTS_DB_USER"),
    ("@PASSWORD@", "REPORTS_DB_PASSWORD"),
):
    text = text.replace(key, os.environ[value])
with open("/opt/reports/etc/settings.ini", "w") as dst:
    dst.write(text)
PY
fi

crond
exec /usr/sbin/sshd -D -e
