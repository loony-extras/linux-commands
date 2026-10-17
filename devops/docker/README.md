# Docker

Images and Compose stacks.

---

## Files

- [Dockerfile.base](Dockerfile.base)
- [docker-compose.yml](docker-compose.yml)

---

## Usage

```bash
cd devops/docker/

# Build multi-stage image (Go → distroless)
docker build -f Dockerfile.base --target production -t myapp:latest .

# Start full stack (app + postgres + redis + nginx)
cp .env.example .env   # fill DB_PASSWORD, REDIS_PASSWORD
docker compose up -d

# Start with monitoring (adds prometheus + grafana)
docker compose --profile monitoring up -d

docker compose logs -f app
```

The compose stack includes:
- **app**: binds to `127.0.0.1:8080` (nginx proxies externally)
- **db**: PostgreSQL 16 with health check
- **cache**: Redis 7 with AOF persistence and maxmemory policy
- **nginx**: reverse proxy with Let's Encrypt volume mounts
- **certbot**: auto-renewal sidecar
- **prometheus + grafana**: optional monitoring profile

---

## Docker Setup and Management

### Installation

```bash
# Official Docker Engine install (Ubuntu)
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Post-install
usermod -aG docker $USER       # Add user to docker group (avoid sudo)
systemctl enable --now docker
```

### Docker Operations

```bash
# Images
docker pull ubuntu:22.04
docker images
docker rmi ubuntu:22.04
docker image prune -f         # Remove dangling images
docker image prune -a         # Remove all unused images

# Containers
docker run -d --name myapp \
  -p 8080:80 \
  -v /var/data:/app/data \
  -e APP_ENV=production \
  --restart unless-stopped \
  --memory 512m \
  --cpus 1.5 \
  myapp:latest

docker ps                     # Running containers
docker ps -a                  # All containers
docker stop myapp
docker start myapp
docker restart myapp
docker rm myapp               # Remove stopped container
docker rm -f myapp            # Force remove running container

# Exec into container
docker exec -it myapp bash
docker exec -it myapp sh      # If no bash

# Logs
docker logs myapp
docker logs -f myapp          # Follow
docker logs --tail 100 myapp
docker logs --since 1h myapp

# Inspect
docker inspect myapp
docker inspect --format '{{.NetworkSettings.IPAddress}}' myapp
docker stats                  # Live resource usage
docker stats --no-stream      # One-shot stats

# Network
docker network create mynet --driver bridge
docker network ls
docker run -d --network mynet --name db postgres:15
docker run -d --network mynet --name app myapp:latest

# Volumes
docker volume create mydata
docker volume ls
docker volume inspect mydata
docker volume rm mydata
docker volume prune

# System cleanup
docker system prune            # Remove stopped containers + dangling images
docker system prune -a         # All unused containers, networks, images
docker system df               # Disk usage

# Save and load images (for air-gapped environments)
docker save myapp:latest | gzip > myapp.tar.gz
docker load < myapp.tar.gz
```

### Production Dockerfile

```dockerfile
# devops/docker/Dockerfile.base
# Multi-stage build: keeps final image small

# Stage 1: Build
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server

# Stage 2: Runtime (minimal image)
FROM gcr.io/distroless/static-debian12

# Run as non-root
USER nonroot:nonroot

# Copy only the binary
COPY --from=builder --chown=nonroot:nonroot /app/server /server

EXPOSE 8080

ENTRYPOINT ["/server"]
```

### Docker Compose Stack

```yaml
# devops/docker/docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    image: myapp:${APP_VERSION:-latest}
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"     # Bind to loopback only (nginx proxies)
    environment:
      - DATABASE_URL=postgres://app:${DB_PASSWORD}@db:5432/myapp
      - REDIS_URL=redis://cache:6379
      - APP_ENV=production
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    volumes:
      - app_data:/app/data
    networks:
      - internal
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: journald
      options:
        tag: "{{.Name}}"

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./configs/postgresql.conf:/etc/postgresql/postgresql.conf:ro
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

  cache:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - internal

  nginx:
    image: nginx:1.25-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./configs/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - app
    networks:
      - internal
      - external

volumes:
  app_data:
  db_data:
  redis_data:
  nginx_logs:

networks:
  internal:
    internal: true        # No external access
  external:
    driver: bridge
```

