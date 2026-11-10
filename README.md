# FinSim

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/bohdanmatveiev15/devops-sim)

FinSim is a learning homelab project: a small payment system for a fictional fintech
company, used to practise DevOps work on a realistic application. FinSim is not a real
brand or product, and all data in it is test data.

The repository contains the application as developers would hand it over, the servers and
processes the platform team inherited, plus `sim`, an internal CLI for tracking work time.

See [docs/architecture.md](docs/architecture.md) and [docs/onboarding.md](docs/onboarding.md).

## Architecture

```mermaid
flowchart LR
    client[Client / curl] -->|":8080"| nginx
    loadgen[load-generator] -->|HTTP| nginx
    nginx -->|":8000"| api[payments-api]
    api -->|"store payment (pending)"| postgres[(postgres)]
    api -->|"LPUSH payment id"| redis[(redis)]
    worker[ledger-worker] -->|"BRPOP payment id"| redis
    worker -->|"update balances and status"| postgres
```

| Service          | Purpose                                                       |
| ---------------- | ------------------------------------------------------------- |
| `payments-api`   | FastAPI service that accepts payments and reads their state   |
| `ledger-worker`  | Moves money between accounts and completes or rejects payments |
| `postgres`       | Stores accounts and payments, seeded with 10 test accounts    |
| `redis`          | Queue of payment ids waiting for processing                   |
| `nginx`          | Reverse proxy from host port 8080 to `payments-api`           |
| `load-generator` | Sends random requests so the system has live traffic          |

## Run

### GitHub Codespaces

This is the primary environment, and it needs only a browser. Select the **Open in GitHub
Codespaces** badge above. When the codespace is ready, `.env.prod` and `.env.staging` already
exist and `bin` is in your `PATH`, so run:

```bash
make up
make ps
make infra-up
```

See [docs/codespaces.md](docs/codespaces.md) for stopping, rebuilding, opening ports and saving
quota.

### WSL2 Ubuntu

You need Docker Engine with the Compose plugin, and `make`. Run this once to create the env
files, the simulation SSH key and the `bastion` and `legacy-vm-01` entries in `~/.ssh/config`:

```bash
export SIM_HOME=~/.devops-sim
export SIM_SSH_PUBKEY="$SIM_HOME/ssh/id_ed25519.pub"
bash .devcontainer/post-create.sh
```

Keep both variables in your shell profile, then start the system:

```bash
make up
make ps
make infra-up
```

### Commands

Application targets work on prod by default. Add `env=staging` to use staging, for example
`make up env=staging` or `make logs env=staging s=payments-api`.

| Command               | Action                                                |
| --------------------- | ----------------------------------------------------- |
| `make up`             | Build and start all services                          |
| `make down`           | Stop and remove the containers                        |
| `make restart`        | Run `down`, then `up`                                 |
| `make ps`             | Show the service state                                |
| `make logs`           | Follow the logs of all services                       |
| `make logs s=nginx`   | Follow the logs of one service                        |
| `make load-on`        | Turn the load generator on                            |
| `make load-off`       | Turn the load generator off                           |
| `make reset`          | Delete all data and start again (asks for y/N)        |
| `make prune`          | Delete unused images and build cache, keep volumes (asks for y/N) |
| `make infra-up`       | Build and start `bastion` and `legacy-vm-01` (prod must be up) |
| `make infra-down`     | Stop and remove the servers                           |
| `make infra-ps`       | Show the state of the servers                         |

Staging listens on port 8081 and is off by default. The load generator reads `ENABLED` and
`RPS` (requests per second) from the env file of the environment. After you change `RPS`, run
`make up` to apply it.

Deployments use `scripts/deploy.sh <env> <git-ref>`, which works from a separate copy of the
repository in `$SIM_HOME/deploy/<env>`.

## API examples

```bash
curl http://localhost:8080/health

curl -X POST http://localhost:8080/payments \
  -H 'Content-Type: application/json' \
  -d '{"from_account": 1, "to_account": 2, "amount": 25.50, "currency": "USD"}'

curl http://localhost:8080/payments/1

curl http://localhost:8080/accounts/1/balance
```

A payment starts as `pending`. The worker then sets it to `completed`, or to `rejected`
if the sender has too little money or the currency does not match both accounts. All test
accounts use USD.

## Business impact

Every failed payment is money the company loses, so these metrics are the basis for future
service level objectives (SLOs). `payments-api` serves them at `/metrics` and `ledger-worker`
on port 9100, in Prometheus format.

| Metric                              | Meaning                                      |
| ----------------------------------- | -------------------------------------------- |
| `finsim_payments_total{status}`     | Payments by `status`                         |
| `finsim_payment_processing_seconds` | Time spent handling one payment (histogram)  |
| `finsim_failed_amount_total`        | Total amount of failed and rejected payments |

## sim

In Codespaces, `sim` is ready to use. In WSL, run this from the repository root to add `bin`
to your `PATH`:

```bash
echo "export PATH=\"$PWD/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
```

| Command               | Action                                                |
| --------------------- | ----------------------------------------------------- |
| `sim init`            | Set the simulation start date                         |
| `sim start`           | Start a work session                                  |
| `sim stop ["note"]`   | Stop the session and save it to the worklog           |
| `sim pause`           | Pause the session; paused time is not counted         |
| `sim resume`          | Resume a paused session                               |
| `sim status`          | Show the session state and minutes worked today       |
| `sim focus [minutes]` | Run a focus timer, 50 minutes by default              |
| `sim dayoff [date]`   | Mark a day off, today by default (`YYYY-MM-DD`)       |
| `sim report [period]` | Show hours for `today` (default) or `week`            |
| `sim standup`         | Print a standup block ready to paste into chat        |
| `sim inbox`           | Show new team chat messages and mark them as read     |
| `sim ticket <number>` | Show a GitHub issue in the terminal                   |
| `sim help`            | Show a short description of all commands              |

Exit codes: `0` success, `1` wrong usage, `2` state error.

`sim standup` lists open GitHub issues as `#number title`, and falls back to `tickets/` if
`gh` is unavailable. When new chat messages have arrived, every `sim` command starts with a
reminder line.

Data is stored outside the repository in `$SIM_HOME`: `/workspaces/.devops-sim` in Codespaces,
and `~/.devops-sim/` by default in WSL. Run `sim standup` from inside
this repository, because it reads the commits and tickets of the current repository. Each
run moves the "last standup" marker, so a second run lists only newer commits.

A simulation day is a working day (Monday to Friday) counted from the `sim init` date,
without days marked with `sim dayoff`. One sprint is five such days.

## chaos

`chaos` starts incidents so you can practise finding and repairing them. What it does stays
hidden until you have resolved the incident.

| Command        | Action                                                     |
| -------------- | ---------------------------------------------------------- |
| `chaos arm`    | Turn random incidents on                                   |
| `chaos disarm` | Turn random incidents off                                  |
| `chaos status` | Show `armed` or `disarmed`, and `Active incident: yes` or `no` |
| `chaos run <file>` | Start an incident from a scenario file                 |
| `chaos resolved` | Mark the active incident as resolved by you              |
| `chaos reveal` | Show what happened, only after `chaos resolved`            |
| `chaos fix`    | Emergency restore of the whole system (asks for y/N)       |

Exit codes: `0` success, `1` wrong usage, `2` state error.

While armed, at most one incident a day can start, at a random moment after 30 minutes of
active `sim` session. You are told about it the way a real team would: a colleague writes in
`sim inbox` a few minutes later.

## Repository layout

| Path               | Content                     |
| ------------------ | --------------------------- |
| `tickets/`         | Work tickets and their format |
| `docs/STATE.md`    | Current state of the project |
| `docs/architecture.md` | Environments, servers and ports |
| `docs/onboarding.md` | Access and working rules for new engineers |
| `infra/`           | `bastion` and `legacy-vm-01` |
| `scripts/`         | Operational scripts         |
| `chaos/`           | Incident scenarios          |
| `docs/runbooks/`   | Operational runbooks        |
| `docs/postmortems/`| Incident reviews            |
| `docs/adr/`        | Architecture decision records |
| `brag/`            | Achievements in STAR format |
