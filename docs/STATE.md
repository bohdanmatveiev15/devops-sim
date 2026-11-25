# FinSim simulation state

Updated at the end of sprint 1 (simulation day 5, Friday 2026-11-20; real date 2026-11-25), after #15 and the retro.

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
- #15: settings.ini permissions changed to 600 (root only), with temporary ops-admin access (approved, used about 15 minutes, returned).
- #16 (PR #17): sprint 1 brag entry and this file.

## Known facts about legacy-reports (legacy-vm-01)

- /etc/cron.d/legacy-reports runs /opt/reports/bin/generate_report.py (Python 3) every 5 minutes as root.
- It reads the payments table (status, amount, created_at; last 24 hours, grouped by status).
- Output: /opt/reports/out (288 files per day, no cleanup). Logs: /var/log/legacy-reports/reports.log and cron.out (no rotation).
- Fixed: /opt/reports/etc/settings.ini (with the DB password) is now -rw------- root:root (#15). The cron job still works as root.
- Open risks: the DB password was world-readable for weeks and is not rotated yet; failures are not monitored; a change of the three columns breaks the reports (Lukas added this to the migration plan).

## Open work

- Sam will create a follow-up ticket: rotate the legacy-reports DB password (it was exposed).
- Backlog: #13 spike, should staging stay on by default on the VPS.
- Ideas for later: cleanup or rotation of reports and logs, an alert when no new report appears, running the cron job as a non-root user.

## Working agreements

- Chat in English with grammar corrections at the end of each Tech Lead message.
- Tickets: from sprint 2, less step-by-step detail (goals and AC, fewer ready commands). Placeholders are always marked. Vague tickets start in sprint 3.
- Git: branch issue-<number>-short-name, PR template, Squash and merge after Approve, then delete the branch.
- Never paste secrets or the public IP into GitHub or chat; write <public-ip>.
- Brag: every Friday the Tech Lead drafts the entry from closed tickets; Bohdan checks the facts (about 5 minutes).
- Session length: 45 minutes to 3 hours; short sessions on tired days are fine.
- Access: admin rights only through an access request in the ticket (what, why, how long, limits), approved by the Tech Lead; use ops-admin for the approved window and write when you left.

## Changes for sprint 2 (from the sprint 1 retro)

- More hands-on terminal work, less writing.
- Every ticket has a comment template with blanks (Before / Change / After / Proof).
- One review round for comments: only missing proof, wrong facts or secrets block a ticket.
- English corrections: only the 2-3 most useful ones per message.

## Skills map (0-3)

Linux CLI 1, Git/GitHub 1, Docker/Compose 1, Networking 1, Security basics 1, Observability 0, CI/CD 0, Cloud/IaC/Kubernetes 0, Technical writing in English 1.
