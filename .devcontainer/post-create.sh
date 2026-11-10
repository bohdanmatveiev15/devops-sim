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
