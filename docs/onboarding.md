# Onboarding

Welcome to the FinSim platform team.

## Access

Servers are reached over SSH through the bastion. The SSH client configuration is prepared
for you in `~/.ssh/config`.

```bash
ssh bastion
ssh legacy-vm-01
```

- Your account on both servers is `bohdan`. It has no `sudo`.
- Only `ops-admin` has `sudo` on `legacy-vm-01`.
- `legacy-vm-01` is not reachable directly. Connections to it go through `bastion`.

## Environments

| Environment | URL                     | Start                  | Stop                     |
| ----------- | ----------------------- | ---------------------- | ------------------------ |
| Prod        | `http://localhost:8080` | `make up`              | `make down`              |
| Staging     | `http://localhost:8081` | `make up env=staging`  | `make down env=staging`  |
| Servers     | see [architecture](architecture.md) | `make infra-up` | `make infra-down`   |

Staging is off by default to save memory. Start it when you need it and stop it afterwards.

## Working rules

**No manual changes in prod.** Prod changes only through the deployment process, and every
deployment needs a ticket of type `type:change`.

```bash
scripts/deploy.sh <env> <git-ref>
```

- Tickets are GitHub issues on the **FinSim Platform** board. Use the **Ticket** template.
- `main` accepts changes only through pull requests. Fill in every section of the pull
  request template, including the rollback plan.

## Day-to-day commands

| Command             | Action                                |
| ------------------- | ------------------------------------- |
| `sim start`, `sim stop` | Start and stop a work session     |
| `sim standup`       | Print your standup block              |
| `sim inbox`         | Read new team chat messages           |
| `sim ticket <n>`    | Show a ticket in the terminal         |

The architecture is described in [architecture.md](architecture.md).
