# Working on the VPS

The VPS is the primary environment: Ubuntu 24.04, 8 GB of RAM and a public IP address.
GitHub Codespaces is the fallback, see [codespaces.md](codespaces.md).

## Set up

You need Docker Engine with the Compose plugin, and `make`. From the repository root, run
this once to create the env files, the simulation SSH key and the `bastion` and
`legacy-vm-01` entries in `~/.ssh/config`:

```bash
export SIM_HOME="$HOME/.devops-sim"
export SIM_SSH_PUBKEY="$SIM_HOME/ssh/id_ed25519.pub"
bash .devcontainer/post-create.sh
echo "export PATH=\"$PWD/bin:\$PATH\"" >> ~/.bashrc
```

Keep both variables in `~/.bashrc` as well, then start the system:

```bash
make up
make ps
make infra-up
```

Before building Docker images, check that at least 5 GB is free with `df -h "$HOME"`.

## Ports

Every published port is bound to `127.0.0.1`, so nothing listens on the public IP address:

| Port | Service          |
| ---- | ---------------- |
| 8080 | prod `nginx`     |
| 8081 | staging `nginx`  |
| 2223 | `bastion` SSH    |

Docker publishes ports past `ufw` and other host firewall rules, so do not change these
bindings to `0.0.0.0` or to a bare port such as `"8080:80"`.

## Open FinSim from your computer

Forward the ports over your SSH connection to the VPS:

```bash
ssh -L 8080:127.0.0.1:8080 -L 8081:127.0.0.1:8081 <user>@<vps-address>
```

While that session is open, `http://localhost:8080` and `http://localhost:8081` on your
computer reach prod and staging.
