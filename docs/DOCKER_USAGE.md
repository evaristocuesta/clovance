# Using Clovance Docker Images

This document shows how to use the Docker images published to GitHub Container Registry (GHCR).

## 🐳 Docker Compose

Create a `.env` file. SMTP is optional: leave its host, username, password, and from-address values empty to run without email. In that case, Clovance cannot send invitations or password-reset emails. If you configure SMTP, provide all four values, including the password.

```
# Container image name for clovance-apiservice
CLOVANCE_APISERVICE_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0

# Default container port for clovance-apiservice
CLOVANCE_APISERVICE_PORT=8080

# Container image name for clovance-frontend
CLOVANCE_FRONTEND_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-frontend:1.0.0

# Parameter frontend-base-url
FRONTEND_BASE_URL=http://localhost:7000

# Parameter postgres-password
POSTGRES_PASSWORD=your_postgres_password

# Parameter postgres-username
POSTGRES_USERNAME=your_postgres_username

# Optional SMTP settings. Leave the host, username, password, and from address
# empty to disable email. If enabled, fill in all four values.
SMTP_FROM_ADDRESS=

# Parameter smtp-from-name
SMTP_FROM_NAME=Clovance

# Parameter smtp-host
SMTP_HOST=

# Parameter smtp-password
SMTP_PASSWORD=

# Parameter smtp-port
SMTP_PORT=587

# Parameter smtp-username
SMTP_USERNAME=

# Parameter volume-source-path
VOLUME_SOURCE_PATH=/home/docker/clovance
```

Use the canonical Compose file, which is also used by both installers:

- [Download `docker-compose.yml`](https://evaristocuesta.github.io/clovance/install/docker-compose.yml)
- Or download it from a terminal:

  ```bash
  curl -fsSLo docker-compose.yml https://evaristocuesta.github.io/clovance/install/docker-compose.yml
  ```

  In PowerShell:

  ```powershell
  Invoke-WebRequest https://evaristocuesta.github.io/clovance/install/docker-compose.yml -OutFile docker-compose.yml
  ```

Keep the `.env` file in the same directory as `docker-compose.yml`.

Start the application:

```bash
docker compose up -d
```

Stop the application:

```bash
docker compose down
```

To also remove the database volume:

```bash
docker compose down -v
```

---

## Published ports and reverse proxy

Only two ports are published to the host. The API and PostgreSQL are reachable only through the internal Docker network.

| Service | Host port | Bind address variable | Default |
|---|---|---|---|
| Frontend (Clovance) | `7000` | `CLOVANCE_BIND_ADDRESS` | `0.0.0.0` |
| Aspire Dashboard | random (see `docker ps`) | `CLOVANCE_DASHBOARD_BIND_ADDRESS` | `0.0.0.0` |

### Direct access by IP and port

With the defaults, Clovance is available at `http://<host-ip>:7000`. Traffic is plain HTTP, so use this on a trusted network.

### Behind a reverse proxy with TLS

To use a domain name and a certificate, put a reverse proxy (nginx, Caddy, Traefik...) in front of Clovance and point it at port `7000`. The proxy must send the `X-Forwarded-Proto` and `X-Forwarded-For` headers; otherwise the refresh cookie is not marked `Secure`. Clovance only trusts these headers when they come from a private network address (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).

If the proxy runs on the same host, close the direct access by binding Clovance to the loopback interface and point the proxy at `127.0.0.1:7000`:

```
CLOVANCE_BIND_ADDRESS=127.0.0.1
```

If the proxy runs on another machine, keep the default (or set the host LAN IP), because the proxy must reach the published port over the network.

In both cases, do not forward port `7000` in your router. Only the proxy port (usually `443`) should be reachable from the internet.

### Aspire Dashboard

The dashboard shows telemetry and the environment of every service. It asks for a browser token that is printed in the container logs (`docker logs <dashboard-container>`). Never expose it to the internet. To reach it only from the host, set:

```
CLOVANCE_DASHBOARD_BIND_ADDRESS=127.0.0.1
```

Check what is published with `docker ps` or `docker compose config`.

---

## 🎯 Pull a Specific Version

```bash
# Stable releases
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:latest

# Pre-releases
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta2
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:2.0.0-rc2
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-alpha3
```

> **Note:** Pre-release versions **do not** update the `latest`, `1`, or `1.0` tags.

---

## 🧪 Run Only the API

```bash
docker run -d \
  --name clovance-api \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  -e ConnectionStrings__DefaultConnection="Host=localhost;Database=clovance;Username=postgres;Password=postgres" \
  ghcr.io/evaristocuesta/clovance/clovance-api:latest
```

---

## 🖥️ Run Only the Frontend

```bash
docker run -d \
  --name clovance-frontend \
  -p 8000:8000 \
  -e API_URL=http://localhost:8080 \
  ghcr.io/evaristocuesta/clovance/clovance-frontend:latest
```

---

## 🔍 Inspect Docker Images

Display image information:

```bash
docker inspect ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```

Display image layers and size:

```bash
docker history ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```

---

## 📊 Multi-Architecture Support

Docker images are published for multiple architectures:

- `linux/amd64` (x86_64)
- `linux/arm64` (Apple Silicon and ARM servers)

Docker automatically pulls the correct image for your platform.

---

## 🚀 GitHub Actions Example

The published Docker images can be used directly in GitHub Actions workflows.

```yaml
- name: Pull Docker images
  run: |
    docker pull ghcr.io/evaristocuesta/clovance/clovance-api:${{ github.ref_name }}
    docker pull ghcr.io/evaristocuesta/clovance/clovance-frontend:${{ github.ref_name }}
```

---

## 📚 Related Documentation

- [Publishing Docker Images](DOCKER_PUBLISH.md)
