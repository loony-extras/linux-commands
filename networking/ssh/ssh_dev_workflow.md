Here are **real-world developer workflows using SSH**—the kind you’ll actually use in day-to-day backend/devops work, not just textbook examples.

---

# 🚀 1. Deploying Code to a Remote Server

Classic workflow for VPS/cloud servers.

### Example flow

```bash
ssh ubuntu@server
cd /var/www/app
git pull origin main
npm install
pm2 restart app
```

### Better (automated via SSH)

```bash
ssh ubuntu@server << EOF
cd /var/www/app
git pull
npm install
pm2 restart app
EOF
```

👉 Used for:

- Node.js apps
- Django/Flask
- Simple production deployments

---

# 🔁 2. Git over SSH (No Passwords, Secure Push/Pull)

Instead of HTTPS:

```bash
git clone git@github.com:user/repo.git
```

### Why this matters

- No password prompts
- Works seamlessly in CI/CD
- Required for private repos

👉 Used daily with platforms like GitHub, GitLab

---

# 📦 3. Remote Docker Management

Control containers on a remote server without logging in manually.

```bash
ssh user@server "docker ps"
ssh user@server "docker restart my_container"
```

### Advanced: Docker over SSH

```bash
export DOCKER_HOST=ssh://user@server
docker ps
```

👉 Feels like you're running Docker locally, but it's remote.

---

# 🧠 4. Editing Remote Code Locally (SSH + Editor)

Using tools like:

- VS Code (Remote SSH extension)

### Workflow

- Connect via SSH in VS Code
- Edit files directly on server
- Run/debug remotely

👉 Super common for:

- Cloud development
- Debugging production issues

---

# 🛠️ 5. Log Monitoring & Debugging

Instead of logging into dashboards:

```bash
ssh user@server
tail -f /var/log/app.log
```

Or one-liner:

```bash
ssh user@server "tail -f /var/log/app.log"
```

👉 Used for:

- Debugging crashes
- Monitoring live traffic
- Checking errors quickly

---

# 🔐 6. Accessing Private Services (Port Forwarding)

Example: Access remote DB securely.

```bash
ssh -L 5432:localhost:5432 user@server
```

Now locally:

```bash
psql -h localhost
```

👉 Used for:

- PostgreSQL, MySQL
- Internal APIs
- Admin dashboards

---

# 🌍 7. Working Behind Firewalls (Jump Hosts)

Production servers often aren’t public.

```bash
ssh -J user@bastion user@private-server
```

👉 Used in:

- AWS VPC setups
- Corporate infra
- Zero-trust networks

---

# 🤖 8. CI/CD Pipelines Using SSH

In CI tools (like GitHub Actions):

```bash
ssh user@server "deploy.sh"
```

### Typical deploy script:

```bash
#!/bin/bash
git pull
docker-compose down
docker-compose up -d --build
```

👉 SSH becomes your deployment backbone.

---

# 💾 9. Backups & Sync (rsync over SSH)

```bash
rsync -avz ./data user@server:/backup/
```

### Real use

- Daily backups
- Sync assets between servers
- Migrate data

---

# 🧪 10. Running Heavy Jobs Remotely

Instead of using your laptop:

```bash
ssh user@server
python train_model.py
```

Or:

```bash
ssh user@server "nohup python job.py &"
```

👉 Used for:

- ML training
- Batch jobs
- Data processing

---

# 🧵 11. Persistent Sessions (tmux over SSH)

```bash
ssh user@server
tmux
```

👉 Even if connection drops:

- Process keeps running
- Reconnect later

---

# 🔄 12. Remote Database Migrations

```bash
ssh user@server
cd app
alembic upgrade head
```

Or:

```bash
ssh user@server "cd app && python manage.py migrate"
```

---

# 🧰 13. Quick Hotfix in Production

```bash
ssh user@server
nano bugfix.js
pm2 restart app
```

👉 Not ideal long-term, but very real-world 😄

---

# 🔍 14. Inspecting System Resources

```bash
ssh user@server
htop
df -h
free -m
```

👉 Debug:

- High CPU
- Memory leaks
- Disk issues

---

# ⚡ 15. One-Liner Power Moves

### Download remote file

```bash
ssh user@server "cat file.log" > local.log
```

### Run multiple servers

```bash
for s in server1 server2; do
  ssh $s "uptime"
done
```

---

# 🧩 Typical Full Workflow (Real Scenario)

A backend dev might:

1. Push code → GitHub
2. CI triggers → SSH into server
3. Pull latest code
4. Restart Docker containers
5. SSH in manually to check logs
6. Use port forwarding to inspect DB
7. Fix bug via SSH + editor

---

# 🧠 The Big Picture

SSH is your:

- Remote terminal
- Secure network tunnel
- Deployment tool
- Debugging console
- Automation backbone

---

If you want, I can break down:

- A **complete production setup (server + SSH + deploy pipeline)**
- Or show a **step-by-step VPS deployment using SSH** tailored for your stack (Node, Python, etc.)
