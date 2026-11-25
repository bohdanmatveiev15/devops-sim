## Onboarding a platform without documentation (homelab project)

- Date: 2026-11-11 to 2026-11-25 (simulation sprint 1)
- Ticket: #3, #4, #5, #6, #12, #14

**Situation:**
The previous engineer left the platform team without any documentation.

**Task:**
I had to understand the platform, check that it is safe, and document it for the next engineer.

**Action:**
- I set up the GitHub labels and the project board, and created the first tickets.
- I verified SSH access to bastion and legacy-vm-01 (through a jump host).
- I reviewed the prod and staging environments: health checks, RAM and disk usage.
- I wrote an access and environments runbook for new engineers (my first PR).
- I verified that FinSim ports are not exposed on the VPS public IP.
- I found out what the undocumented legacy-reports service does on legacy-vm-01.

**Result:**
- The runbook was merged (PR #11): one page for access and environment checks.
- The ports were confirmed closed from two places: the VPS and an outside computer.
- 3 risks in legacy-reports were found and reported, including a world-readable DB password.
