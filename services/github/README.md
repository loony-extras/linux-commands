# GitHub

Repositories, pull requests, releases and Actions from the terminal with the `gh` CLI,
plus self-hosted runners and repository backups.

---

## Files

- [examples.sh](examples.sh): annotated `gh` commands: auth, SSH keys, repos, PRs, issues, releases, Actions, secrets, API
- [github-runner-setup.sh](github-runner-setup.sh): install a self-hosted Actions runner as a systemd service
- [gh-backup-repos.sh](gh-backup-repos.sh): mirror every repo of a user or org to local bare repositories

---

## Setup

```bash
sudo apt install gh            # after adding the GitHub CLI apt repo (see examples.sh)
gh auth login                  # browser login; choose SSH for git
gh auth status
```

For servers and CI, create a **fine-grained personal access token** (Settings → Developer
settings) scoped to the repos and permissions the job needs, then
`gh auth login --with-token < token.txt` or `export GH_TOKEN=...`.

Prefer SSH keys or deploy keys over HTTPS passwords. For a server that only needs to pull
one repo, a read-only **deploy key** is the narrowest option (`gh repo deploy-key add`).

---

## Usage

### Self-hosted Actions runner

Runs workflow jobs on your own server, for example to deploy inside a private network or use
local hardware. Only for **private** repositories: on a public repo, a fork's pull request
could run arbitrary code on the machine.

```bash
# gh must be logged in as a repo admin (or set RUNNER_TOKEN from Settings → Actions → Runners)
sudo bash services/github/github-runner-setup.sh --repo owner/myapp --labels deploy,prod --dry-run
sudo bash services/github/github-runner-setup.sh --repo owner/myapp --labels deploy,prod
sudo bash services/github/github-runner-setup.sh --org myorg --name build-01      # org-wide runner

systemctl list-units 'actions.runner.*'
sudo bash services/github/github-runner-setup.sh --remove --repo owner/myapp      # unregister
```

The script verifies the runner tarball against the SHA-256 published in the release notes,
runs the service as a dedicated `github-runner` user, and installs .NET dependencies.
Target it from a workflow with `runs-on: [self-hosted, deploy]`.

Hardening: give the runner user no sudo (or a narrow sudoers entry for the deploy command
only), keep it on a host that holds nothing else sensitive, and update the runner when
GitHub asks (it auto-updates by default).

### Back up all repositories

GitHub is not a backup. Mirror everything you own:

```bash
bash services/github/gh-backup-repos.sh myuser myorg --dest /var/backup/github --wikis
# First run clones (git clone --mirror); later runs only fetch changes.
# Restore: git clone /var/backup/github/myorg/app.git

# Daily at 03:30 (cron, as a user whose gh login can read the private repos)
30 3 * * * /path/to/gh-backup-repos.sh myuser myorg --dest /var/backup/github >> /var/log/gh-backup.log 2>&1
```

Forks are skipped by default (`--forks` to include); archived repos are included
(`--no-archived` to skip). The script exits non-zero if any repo failed, so cron mail or a
monitoring check notices. Pair it with [system/backup](../../system/backup/) to get the
mirrors off the machine.

### Common workflows

```bash
# Feature branch → PR → auto-merge when CI passes
git switch -c fix-timeout && git commit -am "Fix login timeout" && git push -u origin HEAD
gh pr create --fill && gh pr merge --auto --squash --delete-branch

# Why did CI fail?
gh run list -L 5 && gh run view --log-failed

# Cut a release with generated notes and binaries
git tag v1.4.0 && git push origin v1.4.0
gh release create v1.4.0 ./dist/*.tar.gz --verify-tag --generate-notes

# Install the latest release of a tool on a server
gh release download -R owner/tool -p '*linux_amd64.tar.gz' -D /tmp && tar xzf /tmp/*linux_amd64.tar.gz -C /usr/local/bin
```

GitHub Actions workflow examples (CI, Docker build and push, deploy) are in
[devops/ci-cd](../../devops/ci-cd/).

---

## Security Checklist

- Fine-grained tokens with an expiry, scoped to specific repos; no classic tokens with `repo` on everything.
- Enable 2FA (passkey or TOTP) on every account in the org; require it at the org level.
- Protect `main` with a ruleset: require PRs, passing checks and at least one review.
- Turn on secret scanning push protection (`gh repo edit --enable-secret-scanning-push-protection`).
- Store CI credentials in Actions secrets or environments, never in the repo; prefer OIDC to cloud providers over long-lived keys.
- Self-hosted runners only on private repos, as an unprivileged user.
- Back up repos (`gh-backup-repos.sh`): deleted repos and force-pushes are not recoverable from GitHub.

See also: [networking/ssh](../../networking/ssh/), [devops/ci-cd](../../devops/ci-cd/).
