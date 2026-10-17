# 📊 GitHub – Complete Cheat Sheet

Everything for working with GitHub from a terminal: the `gh` CLI, git workflows, Actions,
search, the API and repository conventions. Checked against **gh 2.102.0**.

`-R owner/repo` works on almost every `gh` command to target a repo other than the current one.
Annotated, runnable versions of many of these are in [examples.sh](examples.sh).

**Contents:** [Setup & Auth](#-setup--auth) · [Git ↔ GitHub](#-git--github) · [Repos](#-repositories) ·
[Pull Requests](#-pull-requests) · [Issues](#-issues-labels--milestones) · [Releases](#-releases--tags) ·
[Actions CLI](#-actions-workflows-runs-cache) · [Secrets](#-secrets--variables) ·
[Workflow YAML](#-workflow-yaml-quick-reference) · [Keys & Security](#-keys-rulesets--security) ·
[Gists · Projects · Codespaces](#-gists-projects-discussions--codespaces) · [Search](#-search) ·
[API](#-gh-api--rest--graphql) · [Output Formatting](#-output-formatting---json---jq---template) ·
[Config & Extensions](#-config-environment-aliases--extensions) · [Repo Files](#-special-repository-files) ·
[Markdown](#-github-flavored-markdown) · [Web Shortcuts](#-web-shortcuts--url-tricks)

---

## 🔐 Setup & Auth

| Category       | Command / Option                     | What it Does                                   | Example                                                  |
| -------------- | ------------------------------------ | ---------------------------------------------- | -------------------------------------------------------- |
| **Install**    | `apt install gh`                     | Install (after adding the GitHub CLI apt repo) | see [examples.sh](examples.sh)                           |
|                | `gh --version`                       | Show version                                   | `gh --version`                                           |
| **Login**      | `gh auth login`                      | Interactive login (browser / device code)      | `gh auth login`                                          |
|                | `-p ssh` / `-p https`                | Git protocol to configure                      | `gh auth login -p ssh`                                   |
|                | `-w`, `--web`                        | Browser login, skip prompts                    | `gh auth login -w`                                       |
|                | `--with-token`                       | Read a token from stdin (servers, CI)          | `gh auth login --with-token < token.txt`                 |
|                | `-h`, `--hostname`                   | GitHub Enterprise host                         | `gh auth login -h github.example.com`                    |
|                | `-s`, `--scopes`                     | Request extra OAuth scopes                     | `gh auth login -s admin:org,delete_repo`                 |
|                | `--skip-ssh-key`                     | Don't offer to upload an SSH key               | `gh auth login -p ssh --skip-ssh-key`                    |
| **Status**     | `gh auth status`                     | Logged-in accounts, scopes, active account     | `gh auth status`                                         |
|                | `gh auth token`                      | Print the token                                | `export GH_TOKEN=$(gh auth token)`                       |
| **Scopes**     | `gh auth refresh -s`                 | Add scopes to existing login                   | `gh auth refresh -s workflow`                            |
|                | `gh auth refresh -r`                 | Remove scopes                                  | `gh auth refresh -r delete_repo`                         |
| **Accounts**   | `gh auth switch`                     | Switch active account                          | `gh auth switch -u work-account`                         |
|                | `gh auth logout`                     | Log out                                        | `gh auth logout -u old-account`                          |
| **Git creds**  | `gh auth setup-git`                  | Use gh as git's HTTPS credential helper        | `gh auth setup-git`                                      |
| **Env token**  | `GH_TOKEN` / `GITHUB_TOKEN`          | Token that overrides stored login              | `GH_TOKEN=ghp_xxx gh repo list`                          |
| **Status page**| `gh status`                          | Assigned issues, review requests, mentions     | `gh status -o myorg`                                     |

Token types: **fine-grained PAT** (per-repo, per-permission, expiring; preferred) · **classic PAT**
(broad scopes like `repo`, `workflow`, `admin:org`) · **`GITHUB_TOKEN`** (automatic in Actions, scoped by `permissions:`).

---

## 🔀 Git ↔ GitHub

| Category            | Command / Option                                  | What it Does                                 | Example                                                        |
| ------------------- | ------------------------------------------------- | -------------------------------------------- | -------------------------------------------------------------- |
| **SSH key**         | `ssh-keygen -t ed25519`                           | Create a key                                 | `ssh-keygen -t ed25519 -C "me@example.com"`                    |
|                     | `gh ssh-key add`                                  | Upload public key                            | `gh ssh-key add ~/.ssh/id_ed25519.pub -t laptop`               |
|                     | `ssh -T git@github.com`                           | Test SSH auth                                | `ssh -T git@github.com`                                        |
|                     | `ssh.github.com:443`                              | SSH over port 443 (port 22 blocked)          | `ssh -T -p 443 git@ssh.github.com`                             |
| **Remotes**         | `git remote add origin`                           | Link local repo to GitHub                    | `git remote add origin git@github.com:me/app.git`              |
|                     | `git remote set-url`                              | Switch HTTPS ↔ SSH                           | `git remote set-url origin git@github.com:me/app.git`          |
|                     | `git push -u origin HEAD`                         | Push branch and set upstream                 | `git push -u origin HEAD`                                      |
| **Fork workflow**   | `gh repo fork --clone`                            | Fork, clone, add `upstream` remote           | `gh repo fork owner/project --clone`                           |
|                     | `git fetch upstream`                              | Get upstream changes                         | `git fetch upstream && git rebase upstream/main`               |
|                     | `gh repo sync`                                    | Sync fork's default branch from upstream     | `gh repo sync me/project`                                      |
| **PR refs**         | `pull/<n>/head`                                   | Fetch any PR without gh                      | `git fetch origin pull/42/head:pr-42`                          |
|                     | `gh pr checkout`                                  | Check out a PR branch (forks too)            | `gh pr checkout 42`                                            |
| **Signing**         | `gpg.format ssh`                                  | Sign commits with an SSH key                 | `git config --global gpg.format ssh`                           |
|                     | `user.signingkey`                                 | Key to sign with                             | `git config --global user.signingkey ~/.ssh/id_ed25519.pub`    |
|                     | `commit.gpgsign true`                             | Sign every commit ("Verified" badge)         | `git config --global commit.gpgsign true`                      |
|                     | `gh ssh-key add --type signing`                   | Register key as a signing key                | `gh ssh-key add key.pub --type signing`                        |
| **Co-author**       | `Co-authored-by:` trailer                         | Credit multiple authors                      | `git commit -m "Fix" -m "Co-authored-by: Ann <ann@x.com>"`     |
| **Close issues**    | `Fixes #n` / `Closes #n` / `Resolves #n`          | Auto-close issue when merged to default      | `git commit -m "Fix timeout (fixes #17)"`                      |
| **Skip CI**         | `[skip ci]` in commit message                     | Don't trigger push/PR workflows              | `git commit -m "Docs [skip ci]"`                               |
| **Large files**     | `git lfs track`                                   | Store big binaries in Git LFS                | `git lfs install && git lfs track "*.psd"`                     |
| **No-reply email**  | `ID+user@users.noreply.github.com`                | Keep your email private in commits           | `git config user.email 1234+me@users.noreply.github.com`       |

---

## 📁 Repositories

| Category        | Command / Option                          | What it Does                                   | Example                                                            |
| --------------- | ----------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------ |
| **Create**      | `gh repo create`                          | New repo (interactive)                         | `gh repo create`                                                   |
|                 | `--private` / `--public` / `--internal`   | Visibility                                     | `gh repo create app --private`                                     |
|                 | `--clone`                                 | Clone after creating                           | `gh repo create app --private --clone`                             |
|                 | `-s`, `--source` + `--push`               | Create from an existing local repo and push    | `gh repo create me/app --private --source=. --push`                |
|                 | `--add-readme` `-g` `-l`                  | Add README, .gitignore template, license       | `gh repo create app --add-readme -g Python -l mit`                 |
|                 | `-p`, `--template`                        | Create from a template repo                    | `gh repo create app -p me/template --private`                      |
|                 | `-d`, `--description`                     | Set description                                | `gh repo create app -d "API server"`                               |
| **Clone/fork**  | `gh repo clone`                           | Clone (`OWNER/REPO` or URL)                    | `gh repo clone cli/cli`                                            |
|                 | `gh repo clone ... -- <git flags>`        | Pass flags to git clone                        | `gh repo clone cli/cli -- --depth 1`                               |
|                 | `gh repo fork`                            | Fork (optionally `--clone`, `--org`)           | `gh repo fork owner/app --org myorg`                               |
| **View/list**   | `gh repo view`                            | README + description                           | `gh repo view cli/cli`                                             |
|                 | `--web`                                   | Open in browser                                | `gh repo view --web`                                               |
|                 | `gh repo list`                            | List repos of a user/org                       | `gh repo list myorg -L 100`                                        |
|                 | `--visibility` `--fork` `--source` `--archived` `--language` | Filter the list           | `gh repo list myorg --source --language go`                        |
| **Settings**    | `gh repo edit`                            | Change settings                                | `gh repo edit --description "New"`                                 |
|                 | `--default-branch`                        | Change default branch                          | `gh repo edit --default-branch main`                               |
|                 | `--delete-branch-on-merge`                | Auto-delete merged branches                    | `gh repo edit --delete-branch-on-merge`                            |
|                 | `--enable-auto-merge`                     | Allow auto-merge                               | `gh repo edit --enable-auto-merge`                                 |
|                 | `--enable-{squash,rebase}-merge` / `--enable-merge-commit` | Allowed merge methods         | `gh repo edit --enable-merge-commit=false`                         |
|                 | `--add-topic` / `--remove-topic`          | Topics                                         | `gh repo edit --add-topic devops,linux`                            |
|                 | `--visibility` + `--accept-visibility-change-consequences` | Public ↔ private              | `gh repo edit --visibility private --accept-visibility-change-consequences` |
|                 | `--enable-{issues,wiki,projects,discussions}` | Toggle features                            | `gh repo edit --enable-wiki=false`                                 |
|                 | `--template`                              | Make it a template repo                        | `gh repo edit --template`                                          |
|                 | `--enable-secret-scanning(-push-protection)` | Secret scanning                             | `gh repo edit --enable-secret-scanning-push-protection`            |
| **Lifecycle**   | `gh repo rename`                          | Rename                                         | `gh repo rename app-v2`                                            |
|                 | `gh repo archive` / `unarchive`           | Read-only archive                              | `gh repo archive me/old --yes`                                     |
|                 | `gh repo delete`                          | Delete (needs `delete_repo` scope)             | `gh repo delete me/old --yes`                                      |
|                 | `gh repo set-default`                     | Pick default repo when several remotes         | `gh repo set-default owner/app`                                    |
| **Content**     | `gh repo read-file` *(preview)*           | Print a file without cloning                   | `gh repo read-file README.md -R cli/cli`                           |
|                 | `gh repo read-dir` *(preview)*            | List a directory without cloning               | `gh repo read-dir docs -R cli/cli`                                 |
|                 | `gh repo gitignore list` / `view`         | .gitignore templates                           | `gh repo gitignore view Node > .gitignore`                         |
|                 | `gh repo license list` / `view`           | License texts                                  | `gh repo license view mit`                                         |
| **Deploy keys** | `gh repo deploy-key add`                  | Per-repo SSH key (read-only; `-w` for write)   | `gh repo deploy-key add key.pub -t web-01`                         |
|                 | `gh repo deploy-key list` / `delete`      | Manage deploy keys                             | `gh repo deploy-key list`                                          |
| **Autolinks**   | `gh repo autolink create`                 | `JIRA-123` → link to your tracker              | `gh repo autolink create JIRA- "https://jira.x/browse/<num>"`      |
| **Browse**      | `gh browse`                               | Open repo in browser                           | `gh browse`                                                        |
|                 | `gh browse <file>:<line>`                 | Open a file at a line                          | `gh browse src/main.go:42`                                         |
|                 | `-b` `-c` `--blame`                       | Branch, commit, blame view                     | `gh browse README.md --blame`                                      |
|                 | `-s` `-a` `-r` `-w` `-p`                  | Settings, Actions, releases, wiki, projects    | `gh browse -s`                                                     |
|                 | `-n`, `--no-browser`                      | Print the URL instead                          | `gh browse -n src/app.ts`                                          |

---

## 🔁 Pull Requests

| Category        | Command / Option                     | What it Does                                    | Example                                                      |
| --------------- | ------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------ |
| **Create**      | `gh pr create`                       | Interactive PR from current branch              | `gh pr create`                                               |
|                 | `-f`, `--fill`                       | Title/body from commits                         | `gh pr create --fill`                                        |
|                 | `--fill-first` / `--fill-verbose`    | First commit only / all commit bodies           | `gh pr create --fill-verbose`                                |
|                 | `-t` `-b` / `-F`                     | Title, body / body from file                    | `gh pr create -t "Fix login" -F body.md`                     |
|                 | `-B`, `--base`                       | Target branch                                   | `gh pr create -B develop --fill`                             |
|                 | `-H`, `--head`                       | Source branch                                   | `gh pr create -H feature/x --fill`                           |
|                 | `-d`, `--draft`                      | Draft PR                                        | `gh pr create --draft --fill`                                |
|                 | `-r` `-a` `-l` `-m` `-p`             | Reviewers, assignees, labels, milestone, project| `gh pr create -r alice,org/team -a @me -l bug --fill`        |
|                 | `-T`, `--template`                   | Use a PR template                               | `gh pr create -T bugfix.md`                                  |
|                 | `--dry-run`                          | Show what would be created                      | `gh pr create --fill --dry-run`                              |
|                 | `-w`, `--web`                        | Finish in the browser                           | `gh pr create -w`                                            |
| **List**        | `gh pr list`                         | Open PRs                                        | `gh pr list`                                                 |
|                 | `-s open\|closed\|merged\|all`       | Filter by state                                 | `gh pr list -s merged -L 50`                                 |
|                 | `-A` `-a` `-l` `-B` `-H` `-d`        | Author, assignee, label, base, head, drafts     | `gh pr list -A @me -l bug`                                   |
|                 | `-S`, `--search`                     | Search syntax                                   | `gh pr list -S "review:required status:success"`             |
|                 | `gh pr status`                       | Your PRs, review requests, current branch PR    | `gh pr status`                                               |
| **Inspect**     | `gh pr view`                         | Show PR (number, URL or branch)                 | `gh pr view 42 --comments`                                   |
|                 | `gh pr diff`                         | Show diff (`--name-only`, `--patch`)            | `gh pr diff 42 --name-only`                                  |
|                 | `gh pr checks`                       | CI status                                       | `gh pr checks 42 --required`                                 |
|                 | `--watch` `--fail-fast`              | Wait until checks finish                        | `gh pr checks --watch --fail-fast`                           |
|                 | `gh pr checkout` / `gh co`           | Check out locally                               | `gh co 42`                                                   |
| **Review**      | `gh pr review --approve`             | Approve                                         | `gh pr review 42 --approve`                                  |
|                 | `--request-changes -b`               | Request changes                                 | `gh pr review 42 -r -b "Add tests"`                          |
|                 | `--comment -b`                       | Review comment                                  | `gh pr review 42 -c -b "Looks good overall"`                 |
|                 | `gh pr comment`                      | Comment on the PR                               | `gh pr comment 42 -b "Rebased"`                              |
| **Update**      | `gh pr edit`                         | Title, body, base, labels, reviewers...         | `gh pr edit 42 --add-reviewer bob --add-label ready`         |
|                 | `gh pr ready` / `--undo`             | Draft → ready (or back)                         | `gh pr ready 42`                                             |
|                 | `gh pr update-branch`                | Bring branch up to date with base               | `gh pr update-branch 42 --rebase`                            |
| **Merge**       | `gh pr merge`                        | Merge (prompts for method)                      | `gh pr merge 42`                                             |
|                 | `-s` / `-r` / `-m`                   | Squash / rebase / merge commit                  | `gh pr merge 42 -s -d`                                       |
|                 | `-d`, `--delete-branch`              | Delete branch after merge                       | `gh pr merge 42 -s -d`                                       |
|                 | `--auto` / `--disable-auto`          | Merge when requirements pass                    | `gh pr merge 42 --auto -s`                                   |
|                 | `--admin`                            | Bypass protections (admins)                     | `gh pr merge 42 --admin -s`                                  |
|                 | `--match-head-commit`                | Only merge if head is this SHA                  | `gh pr merge 42 --match-head-commit abc123`                  |
| **Lifecycle**   | `gh pr close` / `reopen`             | Close (`-c` comment, `-d` delete branch)        | `gh pr close 42 -c "Superseded" -d`                          |
|                 | `gh pr revert`                       | Open a PR that reverts a merged PR              | `gh pr revert 42 -t "Revert: broke login"`                   |
|                 | `gh pr lock` / `unlock`              | Lock conversation                               | `gh pr lock 42`                                              |

---

## 🐞 Issues, Labels & Milestones

| Category       | Command / Option                       | What it Does                               | Example                                                       |
| -------------- | -------------------------------------- | ------------------------------------------ | ------------------------------------------------------------- |
| **Create**     | `gh issue create`                      | New issue (interactive)                    | `gh issue create`                                             |
|                | `-t` `-b` `-F` `-l` `-a` `-m` `-p`     | Title, body, file, labels, assignee, milestone, project | `gh issue create -t "Disk full" -l bug -a @me` |
|                | `-T`, `--template`                     | Use an issue template                      | `gh issue create -T "Bug report"`                             |
| **List**       | `gh issue list`                        | Open issues                                | `gh issue list -l bug -a @me`                                 |
|                | `-s` `-A` `-a` `-l` `-m` `--mention`   | State, author, assignee, label, milestone  | `gh issue list -s closed -m v2.0`                             |
|                | `-S`, `--search`                       | Search syntax                              | `gh issue list -S "no:assignee sort:created-asc"`             |
|                | `gh issue status`                      | Issues assigned to / mentioning you        | `gh issue status`                                             |
| **View/edit**  | `gh issue view`                        | Show issue (`--comments`)                  | `gh issue view 17 --comments`                                 |
|                | `gh issue edit`                        | Change title/body/labels/assignees         | `gh issue edit 17 --add-label p1 --remove-assignee bob`       |
|                | `gh issue comment`                     | Add comment                                | `gh issue comment 17 -b "Fixed in #42"`                       |
| **Lifecycle**  | `gh issue close`                       | Close (`-r completed\|not planned`)        | `gh issue close 17 -r "not planned" -c "Duplicate"`           |
|                | `gh issue reopen` / `delete`           | Reopen / delete                            | `gh issue reopen 17`                                          |
|                | `gh issue transfer`                    | Move to another repo                       | `gh issue transfer 17 owner/other-repo`                       |
|                | `gh issue pin` / `unpin`               | Pin to repo issue list                     | `gh issue pin 17`                                             |
|                | `gh issue lock` / `unlock`             | Lock conversation                          | `gh issue lock 17 -r spam`                                    |
| **Branches**   | `gh issue develop`                     | Create a branch linked to the issue        | `gh issue develop 17 --checkout`                              |
|                | `gh issue develop --list`              | Branches linked to the issue               | `gh issue develop 17 --list`                                  |
| **Labels**     | `gh label list`                        | List labels                                | `gh label list`                                               |
|                | `gh label create`                      | Create (`-c` color, `-d` description)      | `gh label create ops -c 0E8A16 -d "Operations"`               |
|                | `gh label edit` / `delete`             | Edit / delete                              | `gh label edit ops -n operations`                             |
|                | `gh label clone`                       | Copy labels from another repo              | `gh label clone owner/template-repo --force`                  |
| **Milestones** | (API)                                  | List / create milestones                   | `gh api repos/{owner}/{repo}/milestones -f title=v2.0`        |

---

## 🚀 Releases & Tags

| Category       | Command / Option                  | What it Does                                   | Example                                                      |
| -------------- | --------------------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| **Create**     | `gh release create <tag>`         | Create release (creates tag if missing)        | `gh release create v1.4.0`                                   |
|                | `--generate-notes`                | Notes from merged PRs since last release       | `gh release create v1.4.0 --generate-notes`                  |
|                | `--notes-start-tag`               | Start notes from a specific tag                | `gh release create v1.4.0 --generate-notes --notes-start-tag v1.2.0` |
|                | `-n` / `-F` / `--notes-from-tag`  | Notes inline / from file / from tag message    | `gh release create v1.4.0 -F CHANGELOG.md`                   |
|                | `<files...>`                      | Upload assets (`file#Label` sets display name) | `gh release create v1.4.0 dist/*.tar.gz`                     |
|                | `-d` / `-p`                       | Draft / prerelease                             | `gh release create v2.0.0-rc1 -p -d`                         |
|                | `--target`                        | Tag from a branch or SHA                       | `gh release create v1.4.1 --target hotfix`                   |
|                | `--verify-tag`                    | Fail if tag isn't already pushed               | `gh release create v1.4.0 --verify-tag`                      |
|                | `--latest=false`                  | Don't mark as "Latest"                         | `gh release create v1.3.9 --latest=false`                    |
|                | `--fail-on-no-commits`            | Refuse an empty release                        | `gh release create v1.4.1 --fail-on-no-commits`              |
| **Inspect**    | `gh release list` / `view`        | List / show release                            | `gh release view v1.4.0`                                     |
| **Assets**     | `gh release upload`               | Add assets (`--clobber` to replace)            | `gh release upload v1.4.0 app.zip --clobber`                 |
|                | `gh release download`             | Download (`-p` glob, `-D` dir, `-A tar.gz`)    | `gh release download -R cli/cli -p '*linux_amd64.deb'`       |
|                | `gh release delete-asset`         | Remove an asset                                | `gh release delete-asset v1.4.0 app.zip`                     |
| **Edit**       | `gh release edit`                 | Publish draft, change notes, etc.              | `gh release edit v1.4.0 --draft=false`                       |
| **Delete**     | `gh release delete`               | Delete (`--cleanup-tag` removes the tag too)   | `gh release delete v1.4.0 --cleanup-tag --yes`               |
| **Verify**     | `gh release verify` / `verify-asset` | Check release attestation / asset origin    | `gh release verify-asset v1.4.0 ./app.zip`                   |
| **Tags (git)** | `git tag -a` + push               | Annotated tag                                  | `git tag -a v1.4.0 -m "v1.4.0" && git push origin v1.4.0`    |
|                | delete remote tag                 | Remove a pushed tag                            | `git push origin :refs/tags/v1.4.0`                          |

---

## ⚙️ Actions: Workflows, Runs, Cache

| Category       | Command / Option                   | What it Does                                    | Example                                                  |
| -------------- | ---------------------------------- | ----------------------------------------------- | -------------------------------------------------------- |
| **Workflows**  | `gh workflow list`                 | List workflows (`-a` incl. disabled)            | `gh workflow list`                                       |
|                | `gh workflow view`                 | Recent runs of one workflow (`--yaml`)          | `gh workflow view ci.yml --yaml`                         |
|                | `gh workflow run`                  | Trigger `workflow_dispatch`                     | `gh workflow run deploy.yml -r main -f env=staging`      |
|                | `-f` / `-F` / `--json`             | String input / typed input / inputs from stdin  | `echo '{"env":"prod"}' \| gh workflow run deploy.yml --json` |
|                | `gh workflow enable` / `disable`   | Toggle a workflow                               | `gh workflow disable nightly.yml`                        |
| **Runs**       | `gh run list`                      | Recent runs                                     | `gh run list -L 10`                                      |
|                | `-w` `-b` `-s` `-e` `-u` `-c`      | Workflow, branch, status, event, user, commit   | `gh run list -w ci.yml -b main -s failure`               |
|                | `gh run view`                      | Summary of a run (`-v` steps)                   | `gh run view 123456 -v`                                  |
|                | `--log` / `--log-failed`           | Full log / failed steps only                    | `gh run view 123456 --log-failed`                        |
|                | `-j`, `--job`                      | One job                                         | `gh run view --job 789 --log`                            |
|                | `--exit-status`                    | Non-zero exit if run failed                     | `gh run view 123456 --exit-status`                       |
|                | `gh run watch`                     | Live progress (`--exit-status`, `--compact`)    | `gh run watch --exit-status`                             |
|                | `gh run rerun`                     | Re-run (`--failed`, `--debug`, `-j job`)        | `gh run rerun 123456 --failed --debug`                   |
|                | `gh run cancel` / `delete`         | Cancel / delete a run                           | `gh run cancel 123456`                                   |
|                | `gh run download`                  | Download artifacts (`-n` name, `-D` dir)        | `gh run download 123456 -n dist -D ./dist`               |
| **Cache**      | `gh cache list`                    | Actions caches (`--key`, `--ref`, `--sort`)     | `gh cache list --sort size_in_bytes`                     |
|                | `gh cache delete`                  | Delete by key/ID, or `--all`                    | `gh cache delete --all`                                  |
| **Runners**    | (API)                              | Self-hosted runners of a repo                   | `gh api repos/{owner}/{repo}/actions/runners`            |
|                | install script                     | Self-hosted runner as systemd service           | [github-runner-setup.sh](github-runner-setup.sh)         |

---

## 🔑 Secrets & Variables

| Category       | Command / Option                 | What it Does                                    | Example                                                      |
| -------------- | -------------------------------- | ----------------------------------------------- | ------------------------------------------------------------ |
| **Secrets**    | `gh secret set NAME`             | Set repo secret (prompts, or stdin)             | `gh secret set API_KEY < key.txt`                            |
|                | `-b`, `--body`                   | Value inline (ends up in shell history!)        | `gh secret set REGION -b eu-west-1`                          |
|                | `-f`, `--env-file`               | Bulk from a dotenv file                         | `gh secret set -f .env.ci`                                   |
|                | `-e`, `--env`                    | Deployment environment secret                   | `gh secret set DB_PASS -e production`                        |
|                | `-o` + `-v` / `-r`               | Org secret, visibility, selected repos          | `gh secret set NPM_TOKEN -o myorg -v selected -r app1,app2`  |
|                | `-u`, `--user`                   | Codespaces user secret                          | `gh secret set GH_PAT -u -a codespaces`                      |
|                | `-a`, `--app`                    | `actions` / `codespaces` / `dependabot` / `agents` | `gh secret set NPM_TOKEN -a dependabot`                   |
|                | `gh secret list` / `delete`      | List / delete (same scope flags)                | `gh secret list -e production`                               |
| **Variables**  | `gh variable set`                | Plain-text config (`vars.NAME` in workflows)    | `gh variable set AWS_REGION -b eu-central-1`                 |
|                | `-e` / `-o` / `-f`               | Environment / org / dotenv file                 | `gh variable set TAG -e staging -b latest`                   |
|                | `gh variable get` / `list` / `delete` | Read / list / delete                       | `gh variable get AWS_REGION`                                 |

---

## 🧩 Workflow YAML Quick Reference

```yaml
# .github/workflows/ci.yml
name: CI
run-name: CI for ${{ github.ref_name }} by @${{ github.actor }}

on:
  push:
    branches: [main, "release/**"]
    tags: ["v*"]
    paths-ignore: ["docs/**", "**.md"]
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: "17 3 * * 1-5"            # UTC; avoid :00 (busy)
  workflow_dispatch:                   # manual / gh workflow run
    inputs:
      environment:
        type: choice
        options: [staging, production]
        default: staging
  workflow_call:                       # reusable workflow
  release:
    types: [published]

permissions:                           # least privilege for GITHUB_TOKEN
  contents: read

concurrency:                           # cancel older runs on the same ref
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  NODE_VERSION: "22"

defaults:
  run:
    shell: bash

jobs:
  test:
    runs-on: ubuntu-latest             # or [self-hosted, linux, deploy]
    timeout-minutes: 15
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [20, 22]
        exclude:
          - os: macos-latest
            node: 20
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0               # full history (tags, changelogs)
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci && npm test
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: report-${{ matrix.os }}-${{ matrix.node }}
          path: coverage/

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment:
      name: production                 # approvals + env secrets
      url: https://example.com
    permissions:
      contents: read
      id-token: write                  # OIDC to cloud providers (no long-lived keys)
    steps:
      - uses: actions/checkout@v4
      - run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}
          REGION: ${{ vars.AWS_REGION }}
```

| Category           | Syntax                                            | What it Does                                      |
| ------------------ | ------------------------------------------------- | ------------------------------------------------- |
| **Contexts**       | `github.*`                                        | Event data: `sha`, `ref`, `ref_name`, `actor`, `repository`, `event_name`, `run_id`, `event.pull_request.number` |
|                    | `env.*` `vars.*` `secrets.*`                      | Env vars, config variables, secrets               |
|                    | `matrix.*` `strategy.*`                           | Current matrix values                             |
|                    | `needs.<job>.outputs.<name>` / `needs.<job>.result` | Outputs/result of earlier jobs                  |
|                    | `steps.<id>.outputs.<name>` / `steps.<id>.outcome` | Outputs/outcome of earlier steps                |
|                    | `runner.os` `runner.temp` `job.status`            | Runner and job info                               |
|                    | `inputs.*`                                        | `workflow_dispatch` / `workflow_call` inputs      |
| **Status funcs**   | `success()` `failure()` `always()` `cancelled()`  | Step/job conditions in `if:`                      |
| **Functions**      | `contains()` `startsWith()` `endsWith()` `format()` | String helpers                                  |
|                    | `toJSON()` `fromJSON()` `join()` `hashFiles()`    | JSON, arrays, cache keys                          |
| **Outputs**        | `echo "name=value" >> "$GITHUB_OUTPUT"`           | Set a step output                                 |
|                    | `echo "VAR=value" >> "$GITHUB_ENV"`               | Env var for later steps                           |
|                    | `echo "$HOME/bin" >> "$GITHUB_PATH"`              | Add to PATH for later steps                       |
|                    | `echo "### Done ✅" >> "$GITHUB_STEP_SUMMARY"`     | Markdown on the run summary page                  |
| **Annotations**    | `echo "::error file=app.js,line=1::Bad"`          | Error annotation (`::warning`, `::notice` too)    |
|                    | `echo "::add-mask::$TOKEN"`                       | Hide a value in logs                              |
|                    | `echo "::group::Title"` … `echo "::endgroup::"`   | Collapsible log section                           |
| **Debug**          | secret/var `ACTIONS_STEP_DEBUG=true`              | Verbose step logs (or `gh run rerun --debug`)     |
| **Reusable**       | `uses: ./.github/workflows/build.yml` + `secrets: inherit` | Call a reusable workflow                 |
| **Pin actions**    | `uses: actions/checkout@<full-sha>`               | Pin third-party actions to a commit SHA           |
| **Local test**     | `act`                                             | Run workflows locally (nektos/act extension/tool) |

---

## 🛡️ Keys, Rulesets & Security

| Category         | Command / Option                     | What it Does                                   | Example                                                    |
| ---------------- | ------------------------------------ | ---------------------------------------------- | ---------------------------------------------------------- |
| **SSH keys**     | `gh ssh-key list` / `add` / `delete` | Account SSH keys (`--type signing`)            | `gh ssh-key add ~/.ssh/id_ed25519.pub -t laptop`           |
| **GPG keys**     | `gh gpg-key list` / `add` / `delete` | Account GPG keys                               | `gpg --armor --export KEYID \| gh gpg-key add -`           |
| **Rulesets**     | `gh ruleset list`                    | Repo/org rulesets (`-o org`)                   | `gh ruleset list`                                          |
|                  | `gh ruleset view`                    | Show one ruleset                               | `gh ruleset view 42`                                       |
|                  | `gh ruleset check`                   | Rules that apply to a branch                   | `gh ruleset check main`                                    |
| **Protection**   | (API) classic branch protection      | Require PRs/checks on a branch                 | `gh api -X PUT repos/{owner}/{repo}/branches/main/protection --input rules.json` |
| **Attestations** | `gh attestation verify`              | Verify build provenance of an artifact         | `gh attestation verify app.tar.gz -R owner/app`            |
|                  | `gh attestation download`            | Save attestations for offline checks           | `gh attestation download app.tar.gz -R owner/app`          |
| **Alerts**       | (API) Dependabot alerts              | Open dependency alerts                         | `gh api repos/{owner}/{repo}/dependabot/alerts --jq '.[].security_advisory.summary'` |
|                  | (API) code scanning / secret scanning | Security alerts                               | `gh api repos/{owner}/{repo}/secret-scanning/alerts`       |
| **Orgs**         | `gh org list`                        | Your organizations                             | `gh org list`                                              |
|                  | (API) members                        | Org members                                    | `gh api orgs/myorg/members --paginate --jq '.[].login'`    |

---

## 📝 Gists, Projects, Discussions & Codespaces

| Category        | Command / Option                          | What it Does                                  | Example                                                     |
| --------------- | ----------------------------------------- | --------------------------------------------- | ----------------------------------------------------------- |
| **Gists**       | `gh gist create`                          | New gist (secret by default; `--public`)      | `gh gist create notes.md -d "Runbook"`                      |
|                 | `gh gist create -`                        | From stdin (`-f` sets filename)               | `kubectl get pods \| gh gist create - -f pods.txt`          |
|                 | `gh gist list` / `view` / `clone`         | List / show (`--raw`) / clone                 | `gh gist view abc123 --raw`                                 |
|                 | `gh gist edit`                            | Edit, `-a` add file, `-r` remove file         | `gh gist edit abc123 -a extra.sh`                           |
|                 | `gh gist rename` / `delete`               | Rename a file / delete                        | `gh gist delete abc123 --yes`                               |
| **Projects**    | `gh project list`                         | Projects of an owner (`--owner @me`)          | `gh project list --owner myorg`                             |
|                 | `gh project create` / `view` / `close`    | Manage projects (needs `project` scope)       | `gh project create --owner @me --title "Roadmap"`           |
|                 | `gh project item-add`                     | Add issue/PR to a project                     | `gh project item-add 3 --owner myorg --url <issue-url>`     |
|                 | `gh project item-list` / `item-edit`      | List / update items (fields)                  | `gh project item-list 3 --owner myorg --format json`        |
|                 | `gh project field-list` / `field-create`  | Custom fields                                 | `gh project field-list 3 --owner myorg`                     |
|                 | `gh project link`                         | Link project to a repo/team                   | `gh project link 3 --owner myorg -R myorg/app`              |
| **Discussions** | `gh discussion list` / `view` *(preview)* | Read discussions                              | `gh discussion list -R owner/repo`                          |
|                 | `gh discussion create` / `comment`        | Start / reply                                 | `gh discussion create -R owner/repo`                        |
| **Codespaces**  | `gh codespace create`                     | New codespace (`-m` machine, `-b` branch)     | `gh codespace create -R owner/app -b main`                  |
|                 | `gh codespace list` / `view`              | List / details                                | `gh codespace list`                                         |
|                 | `gh codespace ssh`                        | SSH in (`--config` writes ssh config)         | `gh codespace ssh -c my-cs`                                 |
|                 | `gh codespace code`                       | Open in VS Code                               | `gh codespace code -c my-cs`                                |
|                 | `gh codespace ports forward`              | Forward a port locally                        | `gh codespace ports forward 3000:3000 -c my-cs`             |
|                 | `gh codespace cp`                         | Copy files (`remote:` prefix)                 | `gh codespace cp remote:/workspaces/app/log.txt . -c my-cs` |
|                 | `gh codespace stop` / `delete` / `rebuild`| Lifecycle                                     | `gh codespace delete --all --days 7`                        |

---

## 🔍 Search

| Category      | Command / Option                     | What it Does                             | Example                                                          |
| ------------- | ------------------------------------ | ---------------------------------------- | ---------------------------------------------------------------- |
| **Repos**     | `gh search repos`                    | Find repositories                        | `gh search repos "terminal ui" --language=go --stars=">1000"`    |
|               | `--owner` `--topic` `--sort` `--archived` | Filters                             | `gh search repos --topic=homelab --sort=stars`                   |
| **Code**      | `gh search code`                     | Search code                              | `gh search code "set_real_ip_from" --extension conf`             |
|               | `--repo` `--owner` `--language` `--filename` | Filters                          | `gh search code "TODO" --repo owner/app --language python`       |
| **Issues/PRs**| `gh search issues` / `prs`           | Across all repos                         | `gh search prs --author @me --merged --limit 20`                 |
|               | `--state` `--label` `--assignee` `--involves` `--review-requested` | Filters    | `gh search prs --review-requested @me --state open`              |
|               | `--created` `--updated` `--closed`   | Date ranges                              | `gh search issues --repo owner/app --created ">2026-01-01"`      |
| **Commits**   | `gh search commits`                  | Search commit messages                   | `gh search commits "fix timeout" --author me`                    |
| **Web**       | `--web`                              | Open the same search in the browser      | `gh search issues "memory leak" --web`                           |

Search qualifiers (web search, `gh ... -S/--search`, and `gh search` free text):

| Qualifier                                   | Meaning                          | Qualifier                               | Meaning                          |
| ------------------------------------------- | -------------------------------- | --------------------------------------- | -------------------------------- |
| `is:open` `is:closed` `is:merged`           | State                            | `is:pr` `is:issue` `is:draft`           | Type                             |
| `author:@me` `assignee:` `mentions:`        | People                           | `involves:user` `commenter:user`        | Involvement                      |
| `review-requested:@me` `reviewed-by:`       | Review state                     | `review:approved` `review:required`     | Review decision                  |
| `label:bug` `-label:wontfix`                | Label / negation                 | `no:assignee` `no:label` `no:milestone` | Missing field                    |
| `repo:owner/name` `org:myorg` `user:me`     | Scope                            | `in:title` `in:body` `in:comments`      | Where text matches               |
| `created:>2026-01-01` `updated:<@today-7d`  | Dates (`..` for ranges)          | `closed:2026-01-01..2026-03-31`         | Date range                       |
| `stars:>500` `forks:>=10` `size:<1000`      | Repo numbers                     | `language:go` `topic:linux`             | Repo attributes                  |
| `path:src/ extension:yml filename:Dockerfile` | Code location                  | `archived:false` `is:public` `fork:true`| Repo flags                       |
| `sort:created-desc` `sort:updated-asc`      | Ordering                         | `status:success` `status:failure`       | PR CI status                     |
| `"exact phrase"`, `NOT`, `OR`, `(...)`      | Boolean logic                    | `linked:pr` `-linked:pr`                | Issues with/without a linked PR  |

---

## 🌐 gh api – REST & GraphQL

| Category          | Command / Option                 | What it Does                                    | Example                                                              |
| ----------------- | -------------------------------- | ----------------------------------------------- | -------------------------------------------------------------------- |
| **GET**           | `gh api <path>`                  | Authenticated request                           | `gh api user`                                                        |
| **Placeholders**  | `{owner}` `{repo}` `{branch}`    | Filled from the current repo                    | `gh api repos/{owner}/{repo}/pulls`                                  |
| **Method**        | `-X`, `--method`                 | POST/PATCH/PUT/DELETE                           | `gh api -X DELETE repos/{owner}/{repo}/git/refs/heads/old`           |
| **Params**        | `-f key=value`                   | String field                                    | `gh api -X POST repos/{owner}/{repo}/issues -f title="Bug"`          |
|                   | `-F key=value`                   | Typed field (`true`, numbers, `@file`)          | `gh api -X PATCH repos/{owner}/{repo} -F has_wiki=false`             |
|                   | `-F 'arr[]=a'`                   | Array values                                    | `gh api -X POST .../labels -F 'labels[]=bug' -F 'labels[]=p1'`        |
|                   | `--input file` / `--input -`     | Raw JSON body                                   | `gh api -X PUT .../protection --input rules.json`                    |
| **Pagination**    | `--paginate` (+ `--slurp`)       | Follow all pages (one JSON array)               | `gh api repos/{owner}/{repo}/issues --paginate --jq '.[].number'`    |
| **Filter**        | `-q`, `--jq`                     | jq filter (no jq install needed)                | `gh api user --jq .login`                                            |
|                   | `-t`, `--template`               | Go template output                              | `gh api user -t '{{.login}} {{.public_repos}}'`                      |
| **Headers**       | `-H`                             | Extra header                                    | `gh api -H "Accept: application/vnd.github.raw+json" repos/{owner}/{repo}/contents/README.md` |
|                   | `-i`, `--include`                | Show status + headers                           | `gh api -i rate_limit`                                               |
| **Cache**         | `--cache 1h`                     | Cache responses                                 | `gh api --cache 1h orgs/myorg/repos`                                 |
| **GraphQL**       | `gh api graphql -f query=`       | GraphQL query (`-F var=value` for variables)    | `gh api graphql -f query='{ viewer { login } }'`                     |
|                   | `--paginate` + `$endCursor`      | Paginate GraphQL connections                    | see GitHub docs for `pageInfo { hasNextPage endCursor }`             |
| **Rate limit**    | `rate_limit`                     | Remaining requests                              | `gh api rate_limit --jq .resources.core`                             |
| **curl**          | `Authorization: Bearer`          | Without gh                                      | `curl -H "Authorization: Bearer $GH_TOKEN" https://api.github.com/user` |

Useful endpoints: `repos/{owner}/{repo}/contents/<path>` · `.../commits?sha=main` · `.../compare/v1.0...v1.1` ·
`.../actions/runs` · `.../actions/artifacts` · `.../collaborators/<user>` (PUT `-f permission=push`) ·
`.../hooks` (webhooks) · `.../traffic/views` · `.../stats/contributors` · `users/<user>/keys` (public SSH keys) ·
`orgs/<org>/teams` · `notifications` · `search/code?q=...`.

---

## 🧾 Output Formatting: `--json`, `--jq`, `--template`

| Category       | Command / Option              | What it Does                                    | Example                                                                 |
| -------------- | ----------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------- |
| **Fields**     | `--json` (no value)           | Print available fields                          | `gh pr list --json`                                                     |
|                | `--json a,b,c`                | JSON with these fields                          | `gh pr list --json number,title,author`                                 |
| **jq**         | `-q`, `--jq`                  | Filter JSON (built-in jq)                       | `gh pr list --json number,title --jq '.[] \| "\(.number) \(.title)"'`   |
| **Templates**  | `-t`, `--template`            | Go templates                                    | `gh pr list --json number,title -t '{{range .}}{{.number}} {{.title}}{{"\n"}}{{end}}'` |
|                | `tablerow` / `tablerender`    | Aligned columns                                 | `-t '{{range .}}{{tablerow .number .title}}{{end}}'`                    |
|                | `timeago` `truncate` `color` `join` `pluck` `hyperlink` | Template helpers      | `-t '{{range .}}{{timeago .updatedAt}} {{.title}}{{"\n"}}{{end}}'`      |
| **Limit**      | `-L`, `--limit`               | Max items                                       | `gh issue list -L 500 --json number`                                    |

Common fields — **pr**: `number title state author headRefName baseRefName isDraft mergeable reviewDecision statusCheckRollup labels url createdAt mergedAt` ·
**issue**: `number title state author assignees labels milestone comments body url createdAt closedAt` ·
**run**: `databaseId name workflowName status conclusion headBranch event createdAt url` ·
**repo**: `name nameWithOwner description isPrivate isArchived isFork stargazerCount primaryLanguage defaultBranchRef pushedAt url`.

---

## 🛠️ Config, Environment, Aliases & Extensions

| Category        | Command / Option                     | What it Does                                    | Example                                                      |
| --------------- | ------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------ |
| **Config**      | `gh config list` / `get` / `set`     | Read/write settings                             | `gh config set git_protocol ssh`                             |
|                 | keys                                 | `git_protocol` `editor` `pager` `browser` `prompt` `telemetry` `spinner` `color_labels` | `gh config set editor "code --wait"` |
|                 | `gh config clear-cache`              | Clear API cache                                 | `gh config clear-cache`                                      |
| **Env vars**    | `GH_TOKEN` `GH_ENTERPRISE_TOKEN`     | Auth tokens                                     | `GH_TOKEN=... gh pr list`                                    |
|                 | `GH_HOST` `GH_REPO`                  | Default host / repo (`[HOST/]OWNER/REPO`)       | `GH_REPO=owner/app gh issue list`                            |
|                 | `GH_EDITOR` `GH_PAGER` `GH_BROWSER`  | Tools gh launches                               | `GH_PAGER=cat gh pr diff 42`                                 |
|                 | `GH_PROMPT_DISABLED`                 | Never prompt (scripts)                          | `GH_PROMPT_DISABLED=1 gh pr create --fill`                   |
|                 | `GH_DEBUG=1` / `GH_DEBUG=api`        | Verbose / log HTTP traffic                      | `GH_DEBUG=api gh repo view`                                  |
|                 | `GH_CONFIG_DIR`                      | Alternative config directory                    | `GH_CONFIG_DIR=/etc/gh-bot gh auth status`                   |
|                 | `GH_NO_UPDATE_NOTIFIER` `GH_SPINNER_DISABLED` `NO_COLOR` `GH_FORCE_TTY` | Output behaviour | `NO_COLOR=1 gh run list`                                    |
|                 | `GH_TELEMETRY` / `DO_NOT_TRACK`      | Telemetry control                               | `gh config set telemetry disabled`                           |
| **Aliases**     | `gh alias set`                       | Shortcut for a gh command                       | `gh alias set prs 'pr list --author @me'`                    |
|                 | `--shell`                            | Alias that runs a shell command                 | `gh alias set --shell igrep 'gh issue list -L 200 \| grep "$1"'` |
|                 | `gh alias list` / `delete` / `import`| Manage aliases                                  | `gh alias import aliases.yml`                                |
| **Extensions**  | `gh extension search` / `browse`     | Discover extensions                             | `gh extension search dash`                                   |
|                 | `gh extension install`               | Install from a repo                             | `gh extension install dlvhdr/gh-dash`                        |
|                 | `gh extension list` / `upgrade --all` / `remove` | Manage                              | `gh extension upgrade --all`                                 |
|                 | `gh extension create`                | Scaffold your own (`--precompiled go`)          | `gh extension create my-tool`                                |
| **Completion**  | `gh completion -s`                   | Shell completion (bash/zsh/fish/powershell)     | `eval "$(gh completion -s bash)"`                            |
| **Copilot**     | `gh copilot` *(preview)*             | Run the GitHub Copilot CLI                      | `gh copilot`                                                 |
| **Agent tasks** | `gh agent-task create` / `list` / `view` *(preview)* | Copilot coding agent tasks      | `gh agent-task list`                                         |
| **Help**        | `gh help <topic>`                    | `environment`, `formatting`, `exit-codes`, `reference` | `gh help formatting`                                 |

Exit codes: `0` success · `1` failure · `2` cancelled · `4` authentication required (also `8` for pending checks in `gh pr checks`).

---

## 📂 Special Repository Files

| File / Path                                   | Purpose                                                        |
| --------------------------------------------- | -------------------------------------------------------------- |
| `README.md`                                   | Repo landing page (root, `.github/` or `docs/`)                |
| `LICENSE`                                     | License shown in the repo sidebar                              |
| `.github/workflows/*.yml`                     | GitHub Actions workflows                                       |
| `.github/CODEOWNERS`                          | Auto-request reviews: `/infra/ @org/ops`, `*.go @alice`        |
| `.github/dependabot.yml`                      | Automated dependency/Actions update PRs                        |
| `.github/pull_request_template.md`            | Default PR body (`PULL_REQUEST_TEMPLATE/` for several)         |
| `.github/ISSUE_TEMPLATE/*.yml`                | Issue forms; `config.yml` sets `blank_issues_enabled`          |
| `CONTRIBUTING.md`                             | Linked when opening issues/PRs                                 |
| `SECURITY.md`                                 | How to report vulnerabilities (Security tab)                   |
| `CODE_OF_CONDUCT.md` / `SUPPORT.md`           | Community health files                                         |
| `.github/FUNDING.yml`                         | Sponsor button                                                 |
| `CITATION.cff`                                | "Cite this repository" button                                  |
| `.github/release.yml`                         | Categories for `--generate-notes` release notes                |
| `.gitattributes`                              | `linguist-vendored`, `linguist-generated`, LFS, line endings   |
| `<user>/<user>/README.md`                     | Profile README (repo named after your username)                |
| `<org>/.github/profile/README.md`             | Organization profile page                                      |
| `<org>/.github` repo                          | Default templates/health files for all org repos               |
| `.devcontainer/devcontainer.json`             | Codespaces / dev container setup                               |

---

## ✍️ GitHub Flavored Markdown

| Feature              | Syntax                                                  | Result                                    |
| -------------------- | ------------------------------------------------------- | ----------------------------------------- |
| **References**       | `#42`, `owner/repo#42`, `GH-42`                         | Link to issue/PR                          |
|                      | `@user`, `@org/team`                                    | Mention (notifies)                        |
|                      | `a1b2c3d` (SHA)                                         | Link to commit                            |
| **Task lists**       | `- [ ] todo` / `- [x] done`                             | Checkboxes (progress shown in issue list) |
| **Code**             | ```` ```bash ```` … ```` ``` ````                       | Syntax-highlighted block                  |
|                      | ```` ```diff ```` with `+`/`-` lines                    | Diff highlighting                         |
|                      | ```` ```suggestion ```` (in PR review comment)          | One-click "Commit suggestion"             |
| **Alerts**           | `> [!NOTE]` `> [!TIP]` `> [!IMPORTANT]` `> [!WARNING]` `> [!CAUTION]` | Coloured callout boxes      |
| **Collapsible**      | `<details><summary>Logs</summary> … </details>`         | Expandable section                        |
| **Diagrams**         | ```` ```mermaid ````                                    | Mermaid diagrams                          |
| **Math**             | `$x^2$` / `$$ … $$`                                     | LaTeX math                                |
| **Footnotes**        | `Text[^1]` … `[^1]: Note`                               | Footnotes                                 |
| **Permalinks**       | `https://github.com/o/r/blob/<sha>/f.go#L10-L20`        | Renders as a code snippet in comments     |
| **Keyboard**         | `<kbd>Ctrl</kbd>+<kbd>C</kbd>`                          | Key caps                                  |
| **Emoji**            | `:rocket:` `:white_check_mark:`                         | 🚀 ✅                                     |
| **Hide comment**     | `<!-- not rendered -->`                                 | Invisible text (e.g. in templates)        |

---

## ⌨️ Web Shortcuts & URL Tricks

| Category         | Shortcut / URL                                     | What it Does                                   |
| ---------------- | -------------------------------------------------- | ---------------------------------------------- |
| **Anywhere**     | `?`                                                | Show all keyboard shortcuts                    |
|                  | `/` or `s`                                         | Focus search                                   |
|                  | `g` `c` / `g` `i` / `g` `p` / `g` `a`              | Go to Code / Issues / Pull requests / Actions  |
|                  | `Ctrl`+`K`                                         | Command palette                                |
| **Code**         | `t`                                                | File finder                                    |
|                  | `.`                                                | Open repo in github.dev web editor             |
|                  | `y`                                                | Expand URL to a permalink (current SHA)        |
|                  | `b`                                                | Blame view                                     |
|                  | `l`                                                | Jump to line                                   |
| **PRs/issues**   | `c` (on list)                                      | Create new                                     |
|                  | `Ctrl`+`Enter`                                     | Submit comment                                 |
|                  | `r` (with text selected)                           | Quote reply                                    |
| **URLs**         | `/compare/main...feature`                          | Compare branches / open a PR                   |
|                  | `/pull/42.diff` · `/pull/42.patch` · `/commit/<sha>.patch` | Raw diff / patch                       |
|                  | `/blob/main/file#L10-L20`                          | Highlight a line range                         |
|                  | `?w=1` on a diff                                   | Ignore whitespace changes                      |
|                  | `/releases/latest/download/<asset>`                | Stable link to the latest release asset        |
|                  | `raw.githubusercontent.com/o/r/<ref>/path`         | Raw file content                               |
|                  | `github.com/<user>.keys` · `.gpg`                  | A user's public SSH / GPG keys                 |
|                  | `/search?q=...&type=code`                          | Shareable search                               |

---

**See also:** [README.md](README.md) (setup, runner, backups) · [examples.sh](examples.sh) ·
[devops/ci-cd](../../devops/ci-cd/) (workflow examples) · [networking/ssh](../../networking/ssh/)
