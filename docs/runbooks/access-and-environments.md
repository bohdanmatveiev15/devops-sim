# Access and environments runbook

## Access

| server | OS | user | sudo | how to reach |
| --- | --- | --- | --- | --- |
| legacy-vm-01 | Rocky Linux 8.9 | bohdan | no (password required; only ops-admin has sudo) | `ssh legacy-vm-01` (through bastion, ProxyJump) |
| bastion | Ubuntu 24.04.5 LTS | bohdan | no (sudo is not installed) | `ssh bastion` |

## Environments

| environment | port | start command | stop command | health check command | expected result | note |
| --- | --- | --- | --- | --- | --- | --- |
| prod | 8080 | `make up` | `make down` | `curl -s http://localhost:8080/health` | {"status":"ok"} | - |
| staging | 8081 | `make up env=staging` | `make down env=staging` | `curl -s http://localhost:8081/health` | {"status":"ok"} | Stop it after use to save memory |

## Resource usage

| what | value | note |
| --- | --- | --- |
| RAM, prod + infra | 202 MiB | limit: 5 GB | 
| RAM, staging | 117 MiB | - |
| free disk on /workspaces | 6.1 GB | - |

Measured on 2026-11-11, with prod, infra and staging running.

## Open questions

| # | Question |
| --- | --- |
| 1 | What happens if bastion is unavailable, and is there a backup way to reach legacy-vm-01? |
| 2 | Why is sudo not installed on bastion? |

