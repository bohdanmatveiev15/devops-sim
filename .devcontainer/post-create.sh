#!/usr/bin/env bash
#
# Prepares the simulation data directory and local env files.
# Safe to run repeatedly: existing keys and env files are never replaced.

set -euo pipefail

: "${SIM_HOME:?SIM_HOME must be set (see .devcontainer/devcontainer.json)}"

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ssh_dir="$SIM_HOME/ssh"
ssh_key="$ssh_dir/id_ed25519"

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# This key is only for the simulated bastion. It is not a GitHub key.
if [ ! -f "$ssh_key" ]; then
    ssh-keygen -q -t ed25519 -N "" -C "finsim-simulation" -f "$ssh_key"
fi
chmod 600 "$ssh_key"

# Every .env*.example gets a working copy, for example .env.example -> .env.
for example in "$repo_root"/.env*.example; do
    [ -f "$example" ] || continue
    target=${example%.example}
    if [ ! -e "$target" ]; then
        cp "$example" "$target"
    fi
done

# Host keys, the ops-admin password and known_hosts for bastion and legacy-vm-01.
bash "$repo_root/infra/prepare.sh"

# The home directory is wiped on rebuild, so the SSH client config is restored here.
user_ssh_dir="$HOME/.ssh"
ssh_config="$user_ssh_dir/config"
block_begin="# BEGIN FinSim simulation hosts"
block_end="# END FinSim simulation hosts"

mkdir -p "$user_ssh_dir"
chmod 700 "$user_ssh_dir"
touch "$ssh_config"
chmod 600 "$ssh_config"
sed -i "/^$block_begin\$/,/^$block_end\$/d" "$ssh_config"

cat >>"$ssh_config" <<EOF
$block_begin
Host bastion
    HostName localhost
    Port 2223
    User bohdan
    IdentityFile $ssh_key
    IdentitiesOnly yes
    UserKnownHostsFile $SIM_HOME/ssh/known_hosts
    StrictHostKeyChecking yes

Host legacy-vm-01
    HostName legacy-vm-01
    User bohdan
    IdentityFile $ssh_key
    IdentitiesOnly yes
    ProxyJump bastion
    UserKnownHostsFile $SIM_HOME/ssh/known_hosts
    StrictHostKeyChecking yes
$block_end
EOF
