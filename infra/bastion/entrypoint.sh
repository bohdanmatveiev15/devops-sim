#!/bin/bash
set -euo pipefail

install -m 600 /etc/finsim/hostkeys/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key
install -d -o bohdan -g bohdan -m 700 /home/bohdan/.ssh
install -o bohdan -g bohdan -m 600 /etc/finsim/authorized_key.pub /home/bohdan/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
