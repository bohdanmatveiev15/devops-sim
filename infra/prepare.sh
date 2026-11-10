#!/usr/bin/env bash
#
# Prepares the host keys, the ops-admin password and known_hosts in SIM_HOME.
# Safe to run repeatedly: existing keys and the existing password are never replaced.

set -euo pipefail

: "${SIM_HOME:?SIM_HOME must be set}"

umask 077
secrets_dir="$SIM_HOME/secrets"
password_file="$secrets_dir/ops-admin.txt"
known_hosts="$SIM_HOME/ssh/known_hosts"

mkdir -p "$secrets_dir" "$SIM_HOME/ssh"
# Default ACLs on /workspaces override the umask, so modes are set explicitly below.
chmod 700 "$secrets_dir" "$SIM_HOME/ssh"

for host in bastion legacy-vm-01; do
    key_dir="$SIM_HOME/hostkeys/$host"
    mkdir -p "$key_dir"
    chmod 700 "$SIM_HOME/hostkeys" "$key_dir"
    if [ ! -f "$key_dir/ssh_host_ed25519_key" ]; then
        ssh-keygen -q -t ed25519 -N "" -C "$host" -f "$key_dir/ssh_host_ed25519_key"
    fi
    chmod 600 "$key_dir/ssh_host_ed25519_key"
done

if [ ! -s "$password_file" ]; then
    head -c 24 /dev/urandom | base64 | tr -d '/+=\n' >"$password_file"
fi
chmod 600 "$password_file"

# Host keys are stable, so these entries stay valid when containers are recreated.
{
    printf '[localhost]:2223 %s\n' "$(cut -d' ' -f1,2 "$SIM_HOME/hostkeys/bastion/ssh_host_ed25519_key.pub")"
    printf 'legacy-vm-01 %s\n' "$(cut -d' ' -f1,2 "$SIM_HOME/hostkeys/legacy-vm-01/ssh_host_ed25519_key.pub")"
} >"$known_hosts"
