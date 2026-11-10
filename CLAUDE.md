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

## Future staging, bastion, legacy-vm-01 and chaos

These do not exist yet. When they are added:

- They must keep their state in `$SIM_HOME` and use the key `$SIM_HOME/ssh/id_ed25519`.
- `.devcontainer/post-create.sh` currently prepares only that key. Once bastion and
  legacy-vm-01 exist, it must also restore `~/.ssh/config` with entries for both servers
  pointing at that key, because the home directory is wiped on rebuild.
- When staging, bastion, legacy-vm-01, chaos or other parts are added, update this file in the
  same change so it describes the current state.

## Env files

- `post-create.sh` copies each `.env*.example` to the same name without `.example`, only when
  the target does not exist. It never overwrites an existing file.
- This also covers the future `.env.prod.example` and `.env.staging.example`. Whoever adds them
  must add `.env.prod` and `.env.staging` to `.gitignore` in the same change.
- `.env` must stay in `.gitignore`. Never commit env files, keys, passwords or `$SIM_HOME` content.

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

Never reveal scenario names, descriptions or hints in README, docs, commit messages, PR
descriptions or chat.
