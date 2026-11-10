# Working in GitHub Codespaces

FinSim runs in a 2-core, 8 GB codespace and needs only a browser.

## Create a codespace

1. Open <https://codespaces.new/bohdanmatveiev15/devops-sim>.
2. Keep the `2-core` machine type and select **Create codespace**.
3. The first start builds the dev container and takes several minutes. When it finishes, the
   setup log ends with `FinSim codespace ready. Run: make up && sim start`.

## Stop and open a codespace

| Action | How                                                                                 |
| ------ | ----------------------------------------------------------------------------------- |
| Open   | <https://github.com/codespaces>, then select the codespace name                     |
| Stop   | On that page, open the `...` menu of the codespace and select **Stop codespace**    |
| Rebuild | In the browser editor, press `Ctrl+Shift+P` and run **Codespaces: Rebuild Container** |

A codespace also stops by itself after 30 minutes without activity (the default idle timeout).
Stopped codespaces are deleted after 30 days without use (the default retention), and
everything in them is lost, so push your work.

## What survives

| What                                     | Stop | Rebuild                     |
| ---------------------------------------- | ---- | --------------------------- |
| Repository and `.env` in `/workspaces`   | Yes  | Yes                         |
| Simulation data in `/workspaces/.devops-sim` | Yes  | Yes                     |
| Simulation SSH key in `/workspaces/.devops-sim/ssh` | Yes | Yes                 |
| Home directory, including `~/.ssh` and `gh` or Claude Code logins | Yes | No     |
| Running processes and containers         | No   | No                          |
| Docker images and volumes (FinSim database) | Yes | Not guaranteed            |

After a start, run `make up` again, because containers do not start by themselves. Treat the
FinSim database as disposable across a rebuild.

### Interrupted `sim` sessions

If a codespace stops during a work session, the time is not lost. `sim` writes a heartbeat
once a minute, and the session is saved up to the last one. `sim status` reports the
interruption, and `sim stop` or the next `sim start` closes the session.

## Open FinSim in the browser

1. Run `make up`.
2. Open the **Ports** tab next to the terminal.
3. On the line **FinSim prod** (port 8080), select the globe icon. Add a path such as `/health`
   to the address if you need one.

Port 8081 is reserved for **FinSim staging**, which does not exist yet.

Ports are private by default: only your signed-in GitHub account can open them. Keep the
visibility as **Private**, and do not change it in the Ports tab.

## Save quota

The GitHub Free quota is 120 core-hours and 15 GB-months of storage per month. On a 2-core
machine, that is 60 hours of running time.

- Stop the codespace at the end of each session. Compute is counted only while it is active.
- Set a shorter idle timeout in <https://github.com/settings/codespaces>.
- Keep one codespace and delete the ones you do not need, because storage is counted for as
  long as a codespace exists, even when it is stopped.
- The dev container image does not count as storage. See [Dev container image](#dev-container-image).
- Run `make prune` to remove unused Docker images and the build cache. It asks first and
  keeps volumes.
- Check usage in <https://github.com/settings/billing>.

## Dev container image

`.devcontainer/devcontainer.json` has no `image` field, so Codespaces uses its default image.
The version is not pinned: the image changes when GitHub updates it. It already includes
Docker, Python, Node and `gh`, so the only added feature is Claude Code.

According to the GitHub documentation, containers based on the default image do not count
toward storage, even with added features. Files in the repository and files you add still count.

WSL does not use the dev container.

If a rebuild ends in a recovery container, the fallback is to add an `image` field back to
`.devcontainer/devcontainer.json`, then rebuild:

```json
"image": "mcr.microsoft.com/devcontainers/universal:6",
```

The GitHub documentation does not confirm that an image set explicitly is excluded from
storage, so check your usage after this change.

## GitHub Project board access

The `GITHUB_TOKEN` built into Codespaces has no `project` scope. With it, `gh project list`
can return an empty list without an error, even if you have projects, so an empty list
proves nothing.

`gh` prefers `GITHUB_TOKEN` over a stored login, so sign in with the variable removed:

```bash
env -u GITHUB_TOKEN gh auth login --hostname github.com --git-protocol https --web --scopes project
```

Follow the one-time code and URL it prints. Then run project commands the same way, or unset
the variable for the current terminal only:

```bash
env -u GITHUB_TOKEN gh project list --owner "$GITHUB_USER"

unset GITHUB_TOKEN
gh project list --owner "$GITHUB_USER"
```

The login is stored in the home directory, so repeat it after a rebuild.
