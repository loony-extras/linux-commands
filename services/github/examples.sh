#!/usr/bin/env bash
# =============================================================================
# GitHub — annotated command examples (gh CLI, git over SSH, REST/GraphQL API)
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# Checked against gh 2.102.0.
# =============================================================================

# ---------------------------------------------------------------------------
### gh — install
# ---------------------------------------------------------------------------
# Official apt repository (Debian/Ubuntu)
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update && sudo apt install gh

gh --version
gh completion -s bash | sudo tee /etc/bash_completion.d/gh >/dev/null   # Tab completion

# ---------------------------------------------------------------------------
### gh auth — login, tokens and git credentials
# ---------------------------------------------------------------------------
gh auth login                           # Interactive: browser/device code, picks git protocol
gh auth login -p ssh --skip-ssh-key     # Use SSH for git, don't upload a key
gh auth login --with-token < token.txt  # Non-interactive with a PAT (servers, CI)
gh auth status                          # Accounts, scopes, active account
gh auth refresh -s workflow,admin:org   # Add scopes to the current login
gh auth switch                          # Switch between logged-in accounts
gh auth token                           # Print the token (pipe into other tools)
gh auth setup-git                       # Use gh as git's credential helper for HTTPS
gh auth logout
export GH_TOKEN=...                     # Env token overrides stored login (CI, scripts)

# ---------------------------------------------------------------------------
### git over SSH — keys for GitHub
# ---------------------------------------------------------------------------
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519_github
gh ssh-key add ~/.ssh/id_ed25519_github.pub --title "$(hostname)"
gh ssh-key add ~/.ssh/id_ed25519_github.pub --type signing --title "signing $(hostname)"
gh ssh-key list
ssh -T git@github.com                   # "Hi <user>! You've successfully authenticated"

# Sign commits with the SSH key (shows "Verified" on GitHub)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519_github.pub
git config --global commit.gpgsign true

# Deploy key: read-only (or -w) access to ONE repo, e.g. for a server pulling code
ssh-keygen -t ed25519 -N "" -f ~/.ssh/deploy_myapp
gh repo deploy-key add ~/.ssh/deploy_myapp.pub -R owner/myapp --title "web-01"
gh repo deploy-key list -R owner/myapp

# ---------------------------------------------------------------------------
### gh repo — create, clone, fork, settings
# ---------------------------------------------------------------------------
gh repo create myapp --private --clone --add-readme --gitignore Node --license mit
gh repo create owner/myapp --private --source=. --remote=origin --push   # From an existing local repo
gh repo clone owner/myapp
gh repo clone owner/myapp -- --depth 1  # Extra args go to git clone
gh repo fork owner/project --clone      # Fork + clone + set upstream remote
gh repo sync                            # Sync your fork's default branch from upstream
gh repo view owner/myapp --web
gh repo list owner --limit 200 --json nameWithOwner,visibility,isArchived \
  --jq '.[] | select(.isArchived | not) | .nameWithOwner'

gh repo edit --delete-branch-on-merge --enable-auto-merge --enable-squash-merge \
  --enable-merge-commit=false --enable-rebase-merge=false
gh repo edit --default-branch main
gh repo edit --add-topic linux,devops --description "Ops toolkit"
gh repo edit --visibility private --accept-visibility-change-consequences
gh repo rename myapp-v2
gh repo archive owner/oldapp --yes
gh repo delete owner/oldapp --yes       # Needs the delete_repo scope

# ---------------------------------------------------------------------------
### gh pr — pull requests
# ---------------------------------------------------------------------------
gh pr create --fill                     # Title/body from commits, prompts for the rest
gh pr create -B main -t "Fix login timeout" -F pr-body.md -r alice,org/backend -l bug
gh pr create --draft --fill
gh pr list                              # Open PRs
gh pr list --author @me --state all
gh pr list --search "review-requested:@me" --json number,title,url --jq '.[] | "\(.number) \(.title)"'
gh pr status                            # PRs involving you
gh pr view 42 --comments
gh pr diff 42
gh pr checkout 42                       # Check out locally (alias: gh co 42)
gh pr checks 42 --watch --fail-fast     # Wait for CI
gh pr review 42 --approve
gh pr review 42 --request-changes -b "Please add a test"
gh pr comment 42 -b "LGTM after CI"
gh pr ready 42                          # Draft → ready for review
gh pr merge 42 --squash --delete-branch
gh pr merge 42 --auto --squash          # Merge automatically once checks/reviews pass
gh pr update-branch 42                  # Merge base into the PR branch
gh pr close 42 -c "Superseded by #57"

# ---------------------------------------------------------------------------
### gh issue — issues and labels
# ---------------------------------------------------------------------------
gh issue create -t "Disk full on web-01" -b "Alert fired at 03:12" -l bug,ops -a @me
gh issue list --label bug --state open
gh issue list --search "is:open no:assignee sort:created-asc"
gh issue view 17 --comments
gh issue comment 17 -b "Root cause: logrotate not running"
gh issue edit 17 --add-label resolved --remove-label triage
gh issue develop 17 --checkout          # Create a linked branch and switch to it
gh issue close 17 -r completed
gh label create ops --color 0E8A16 --description "Operations"
gh label list

# ---------------------------------------------------------------------------
### gh release — tags, notes and assets
# ---------------------------------------------------------------------------
gh release create v1.4.0 --generate-notes                  # Tag + notes from merged PRs
gh release create v1.4.0 ./dist/*.tar.gz --title "v1.4.0" -F CHANGELOG.md
gh release create v2.0.0-rc.1 --prerelease --draft --generate-notes
gh release create v1.4.0 --verify-tag --notes-from-tag     # Tag must already exist
gh release list
gh release view v1.4.0
gh release upload v1.4.0 ./dist/app-linux-arm64.tar.gz --clobber
gh release download v1.4.0 -p '*linux-amd64*' -D /tmp/app # Download matching assets
gh release download -R cli/cli -p '*_linux_amd64.tar.gz'  # Latest release of another repo
gh release edit v1.4.0 --draft=false
gh release delete v1.4.0-bad --cleanup-tag --yes

# ---------------------------------------------------------------------------
### gh run / gh workflow — GitHub Actions
# ---------------------------------------------------------------------------
gh workflow list
gh workflow run deploy.yml -r main -f environment=staging   # workflow_dispatch with inputs
gh workflow view deploy.yml
gh workflow disable nightly.yml

gh run list -L 10
gh run list -w deploy.yml -b main -s failure
gh run watch --exit-status              # Pick a running run; non-zero exit if it fails
gh run view "$RUN_ID"                    # Summary: jobs, annotations, artifacts
gh run view "$RUN_ID" --log-failed       # Only logs of failed steps
gh run view "$RUN_ID" --job "$JOB_ID" --log
gh run rerun "$RUN_ID" --failed          # Re-run only the failed jobs
gh run cancel "$RUN_ID"
gh run download "$RUN_ID" -n build-output -D ./artifact

gh cache list
gh cache delete --all                   # Clear Actions caches (e.g. corrupted node_modules)

# ---------------------------------------------------------------------------
### gh secret / gh variable — Actions configuration
# ---------------------------------------------------------------------------
gh secret set DEPLOY_KEY < ~/.ssh/deploy_myapp          # Value from stdin (not shell history)
gh secret set DB_PASSWORD --env production              # Environment secret
gh secret set -f .env.ci                                # Bulk from a dotenv file
gh secret set NPM_TOKEN --org myorg --visibility selected --repos app1,app2
gh secret list
gh secret delete OLD_TOKEN
gh variable set AWS_REGION --body eu-central-1
gh variable set IMAGE_TAG --env staging --body latest
gh variable list
gh variable get AWS_REGION

# ---------------------------------------------------------------------------
### gh api — REST and GraphQL from the shell
# ---------------------------------------------------------------------------
gh api user --jq .login                                    # Who am I?
gh api repos/{owner}/{repo} --jq '.default_branch'         # {owner}/{repo} = current repo
gh api repos/owner/myapp/branches --paginate --jq '.[].name'
gh api -X POST repos/owner/myapp/issues -f title="From API" -f body="Created by script"
gh api -X PATCH repos/owner/myapp -F has_wiki=false        # -F sends typed values (bool/int)
gh api repos/owner/myapp/collaborators/alice -X PUT -f permission=push
gh api rate_limit --jq '.resources.core | "\(.remaining)/\(.limit) left"'
gh api orgs/myorg/members --paginate --jq '.[].login'

# Branch protection (classic) on main: require PRs + passing "test" check
gh api -X PUT repos/owner/myapp/branches/main/protection --input - <<'EOF'
{"required_status_checks": {"strict": true, "contexts": ["test"]},
 "enforce_admins": true,
 "required_pull_request_reviews": {"required_approving_review_count": 1},
 "restrictions": null}
EOF
gh ruleset list                          # Newer rulesets (preferred over classic protection)

# GraphQL
gh api graphql -f query='query { viewer { login repositories(first: 5, orderBy: {field: PUSHED_AT, direction: DESC}) { nodes { nameWithOwner pushedAt } } } }' \
  --jq '.data.viewer.repositories.nodes[] | "\(.pushedAt) \(.nameWithOwner)"'

# Plain curl with a token (no gh installed)
curl -sS -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/user | jq .login

# ---------------------------------------------------------------------------
### gh search, gist, browse and extensions
# ---------------------------------------------------------------------------
gh search repos "nginx config" --language=shell --sort=stars --limit 10
gh search code "set_real_ip_from" --extension conf
gh search issues "is:open label:bug" --repo owner/myapp
gh search prs --author @me --merged --limit 20

gh gist create notes.md --desc "Runbook"           # Secret gist by default
gh gist create script.sh --public
gh gist list
gh gist view "$GIST_ID" --raw > script.sh

gh browse                               # Open the current repo in the browser
gh browse src/main.go:42                # Open a file at a line
gh status                               # Your notifications, review requests, mentions

gh extension search dash
gh extension install dlvhdr/gh-dash     # TUI dashboard for PRs/issues
gh extension list
gh alias set prs 'pr list --author @me' # gh prs
