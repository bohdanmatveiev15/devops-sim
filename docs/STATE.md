# FinSim simulation state

Updated at the end of sprint 1 (simulation day 5, Friday 2026-11-20; real date 2026-11-25).

## Where we are

- Roadmap phase 1 (onboarding) is done. Phase 2 (Linux and bash, the legacy service) has started.
- Next sprint: sprint 2, starting on simulation day 6 (Monday 2026-11-23).

## Environment

- Primary environment: a VPS (Ubuntu 24.04, 8 GB RAM, public IP). Codespaces is the fallback. See docs/vps.md.
- All published ports are bound to 127.0.0.1 (verified from the VPS and from outside).
- Measured on the VPS (2026-11-20): prod + infra 136 MiB RAM, staging 122 MiB, 141 GB free disk.
- Staging is off by default (the rule is under review in #13).
- The sim clock moves only on real dates with work (sim work or sim start). After 30 minutes without terminal input, the session closes by itself: run `sim work` every 20-25 minutes when working in the browser.

## Done in sprint 1

- #3: labels and the FinSim Platform board.
- #4: SSH access to bastion and legacy-vm-01 checked.
- #5: prod and staging reviewed.
- #6 (PR #11): docs/runbooks/access-and-environments.md.
- #12: ports confirmed not exposed on the public IP.
- #14: legacy-reports discovery.

## Known facts about legacy-reports (legacy-vm-01)

- /etc/cron.d/legacy-reports runs /opt/reports/bin/generate_report.py (Python 3) every 5 minutes as root.
- It reads the payments table (status, amount, created_at; last 24 hours, grouped by status).
- Output: /opt/reports/out (288 files per day, no cleanup). Logs: /var/log/legacy-reports/reports.log and cron.out (no rotation).
- Risks: the config /opt/reports/etc/settings.ini with the DB password is world-readable; failures are not monitored; a change of the three columns breaks the reports (Lukas added this to the migration plan).

## Open work

- To do: "Restrict access to the legacy-reports config with the DB password" (Sam's request, type:change, needs an access request).
- Backlog: #13 spike, should staging stay on by default on the VPS.
- Ideas for later: cleanup or rotation of reports and logs, an alert when no new report appears, running the cron job as a non-root user.

## Working agreements

- Chat in English with grammar corrections at the end of each Tech Lead message.
- Tickets: from sprint 2, less step-by-step detail (goals and AC, fewer ready commands). Placeholders are always marked. Vague tickets start in sprint 3.
- Git: branch issue-<number>-short-name, PR template, Squash and merge after Approve, then delete the branch.
- Never paste secrets or the public IP into GitHub or chat; write <public-ip>.
- Brag: every Friday the Tech Lead drafts the entry from closed tickets; Bohdan checks the facts (about 5 minutes).
- Session length: 45 minutes to 3 hours; short sessions on tired days are fine.

## Skills map (0-3)

Linux CLI 1, Git/GitHub 1, Docker/Compose 1, Networking 1, Security basics 1, Observability 0, CI/CD 0, Cloud/IaC/Kubernetes 0, Technical writing in English 1.
