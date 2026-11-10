# Rules for Claude Code sessions

devops-sim is a learning simulator of Junior DevOps work at FinSim, a fictional fintech
company. Claude builds the simulation environment. The human does the DevOps tickets.

## Environment

- The primary environment is GitHub Codespaces on a 2-core, 8 GB machine, used only through
  a browser. Local WSL2 Ubuntu stays supported, so changes must work in both.
- The budget is $0: GitHub Free quota only (120 core-hours and 15 GB-months of storage).
- No dependency on Windows. `powershell.exe` in `sim focus` is optional and must keep its
  terminal fallback. Do not add `/mnt/c` or paths such as `~/devops-sim`.
- Use paths relative to the repository root.

## Workflow

- Talk to the human in Ukrainian. Write code, comments, docs and commit messages in English.
- Work in a branch and open a pull request.
- Never merge pull requests and never push directly to `main`.

## Disk and memory

- Never build the dev container or run the devcontainer CLI inside a codespace. It is tested
  only through **Rebuild Container**.
- Before building Docker images, check `df -h /workspaces`. Stop and ask if less than 5 GB is free.
- Prod plus infra must stay under 5 GB of RAM.

## Simulation data

- Simulation data lives only in `$SIM_HOME`. In Codespaces that is `/workspaces/.devops-sim`;
  in WSL it defaults to `~/.devops-sim`. In Codespaces, only `/workspaces` survives a rebuild.
- Test `sim` and `chaos` only with a temporary `SIM_HOME` under `/tmp`. Never run them against
  the real `$SIM_HOME`, and never run `sim init`: the human does that on the start day.
- The bastion public key comes from `SIM_SSH_PUBKEY`. In Codespaces that is
  `$SIM_HOME/ssh/id_ed25519.pub`; in WSL it defaults to `~/.ssh/id_ed25519.pub`.

## Staging, bastion, legacy-vm-01 and chaos

Current state:

- Compose projects: `finsim-prod` (port 8080), `finsim-staging` (port 8081, off by default) and
  `finsim-infra` (`bastion` on `127.0.0.1:2223`, and `legacy-vm-01` with no host port). Port 2222
  belongs to the Codespaces SSH server, so do not use it.
- `legacy-vm-01` joins the `finsim-prod_default` network, so prod must be up before `make infra-up`.
- They keep their state in `$SIM_HOME` and use the key `$SIM_HOME/ssh/id_ed25519`. `$SIM_HOME` also
  holds stable host keys (`hostkeys/`), `ssh/known_hosts`, the `ops-admin` password
  (`secrets/ops-admin.txt`, mode 600, never shown, printed or logged) and deployment copies (`deploy/`).
- `.devcontainer/post-create.sh` restores `~/.ssh/config` with entries for both servers, because
  the home directory is wiped on rebuild. `infra/prepare.sh` creates the host keys and the password.
- `scripts/deploy.sh` works only in `$SIM_HOME/deploy/<env>` and never touches the working folder.

Chaos scenario limits:

- Any space a scenario fills is size-bounded (a tmpfs or a file of at most 200 MB) and is never
  the real `/workspaces` disk.
- A scenario that adds load uses at most one CPU core and 500 MB of extra RAM.
- `chaos fix` always removes everything a scenario created.
- Scenarios change only containers, volumes, repository files and `$SIM_HOME`. They never touch
  `~/.ssh`, `.devcontainer` or Codespace settings.

When staging, bastion, legacy-vm-01, chaos or other parts change or are added, update this file in
the same change so it describes the current state.

## Env files

- `post-create.sh` copies each `.env*.example` to the same name without `.example`, only when
  the target does not exist. It never overwrites an existing file.
- The examples are `.env.prod.example` and `.env.staging.example`.
- `.env`, `.env.prod` and `.env.staging` must stay in `.gitignore`. Never commit env files, keys,
  passwords or `$SIM_HOME` content.

## Human tickets: do not do these

Do not implement, configure or partly prepare the following. They are the human's tickets:

- Monitoring: Prometheus, Grafana, Alertmanager, Loki and alert rules. Application-level
  `/metrics` endpoints written as app code are allowed.
- CI/CD
- Healthchecks: Docker and compose healthchecks. The app's `/health` endpoint already exists
  and stays.
- Resource limits
- Hardening
- Terraform
- Kubernetes
- Vault
- Messenger notifications

Deliberately outdated or unreliable inherited parts (for example `scripts/deploy.sh`,
legacy-reports, missing log rotation, missing docs) must not be fixed or improved. They are the
human's tickets.

If a task seems to need one of these, stop and ask.

## chaos/scenarios.dat

Never read, decode or show the content of `chaos/scenarios.dat`, by any means.

The only exception is creating and testing it. The human approved this way of working: a
dedicated subagent writes, encodes and fixes the scenarios, deletes the plain text and reports
only scenario numbers with OK or FAIL. Everyone else exercises scenarios only through `bin/chaos`
with hidden output, and reports only scenario numbers with OK or FAIL.

Never reveal scenario names, descriptions or hints in README, docs, commit messages, PR
descriptions or chat.
