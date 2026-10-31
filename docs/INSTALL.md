# Installing Clovance

Clovance ships with cross-platform installers for Windows, Linux, and macOS. They check Docker, ask a few questions, generate the configuration, pull the images, and start the app.

## 🚀 Quick install

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

You can also run the scripts directly from a local checkout:

```bash
# Linux / macOS
./docs/install/install.sh

# Windows
.\docs\install\install.ps1
```

## 📋 Prerequisites

- Docker (Docker Desktop on Windows/macOS, or Docker Engine on Linux).
- Docker Compose plugin v2 (`docker compose`, not the legacy `docker-compose`).
- The Docker daemon must be running.

The installer verifies these before doing anything else.

## ⚙️ Install parameters

During installation you will be prompted for the following values (defaults shown in brackets):

| Prompt | Default | Description |
|---|---|---|
| Install directory | `~/clovance` (Linux/macOS), `%USERPROFILE%\clovance` (Windows) | Where `.env`, `docker-compose.yml`, and data are stored. |
| Image version tag | `latest` | Docker image tag to pull (e.g. `1.0.0`). Note: tags do **not** include a leading `v`. |
| Frontend host port | `7000` | Host port exposed for the Clovance UI. |
| API container port | `8080` | Internal port of the API service. |
| Bind address (frontend) | `0.0.0.0` | Interface the frontend binds to. Use `127.0.0.1` to restrict to localhost. |
| Bind address (dashboard) | `127.0.0.1` | Interface the Aspire dashboard binds to. |
| PostgreSQL username | `clovance` | Database user. |
| PostgreSQL password | *(auto-generated)* | Leave empty to generate a random password. |
| SMTP host | `smtp.example.com` | Mail server used for invitations and password resets. |
| SMTP port | `587` | Mail server port. |
| SMTP username | `your_smtp_username` | Mail server username. |
| SMTP password | *(empty)* | Mail server password. |
| SMTP from address | `your_smtp_from_address@example.com` | Sender address. |
| SMTP from name | `Clovance` | Sender display name. |
| Frontend base URL | `http://localhost:7000` | Public URL of the frontend (used by the API). |

Data is stored under `<install-dir>/data` (Postgres data and the JWT key).

Re-running the installer over an existing installation is safe: the values in `.env` are used as prompt defaults and the current PostgreSQL password is kept (the `POSTGRES_PASSWORD` value is only used when the database is created).

## 🔄 Update

To upgrade to a new version:

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/update.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/update.ps1 | iex
```

Or, from a local checkout:

```bash
# Linux / macOS
./docs/install/update.sh

# Windows
.\docs\install\update.ps1
```

Both wrappers call `install.sh update` / `install.ps1 update`, so these are equivalent:

```bash
./install.sh update      # Linux / macOS
.\install.ps1 update     # Windows
```

You will be asked for the install directory and the new image version tag. The script backs up `.env` to `.env.bak`, updates the image tags, pulls the new images, and recreates the containers. It fails with an error (and keeps `.env.bak`) if the images cannot be pulled or the containers do not come back up.

## 🗑️ Uninstall

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/uninstall.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/uninstall.ps1 | iex
```

Or, from a local checkout:

```bash
# Linux / macOS
./docs/install/uninstall.sh

# Windows
.\docs\install\uninstall.ps1
```

Both wrappers call `install.sh uninstall` / `install.ps1 uninstall`, so these are equivalent:

```bash
./install.sh uninstall      # Linux / macOS
.\install.ps1 uninstall     # Windows
```

The script stops and removes the containers, then asks:

1. **Remove data volumes (postgres + jwt)?** — answer `y` to delete the database and JWT key.
2. **Remove generated config files (.env, docker-compose.yml)?** — answer `y` to clean up the configuration.

Nothing is deleted if the containers cannot be stopped first, and if Docker is not running the script aborts with an error instead of pretending to succeed.

Docker images are **not** removed. To delete them too:

```bash
docker image rm ghcr.io/evaristocuesta/clovance/clovance-api:latest ghcr.io/evaristocuesta/clovance/clovance-frontend:latest
```

On Linux/macOS, if the data directory was created by the container (root-owned), the script will try `sudo` automatically; if that fails, run `sudo rm -rf <install-dir>/data` manually.

## 🛠️ Troubleshooting

- **Docker not running**: start Docker Desktop / the Docker daemon and retry. The installers verify the daemon before writing any configuration and exit with an error if it is down.
- **Compose v2 missing**: upgrade Docker or install the Compose plugin.
- **Permission denied on data removal (Linux)**: use `sudo rm -rf <install-dir>/data`.
- **Port already in use**: choose a different frontend port during install, or stop the conflicting service.
- **The API restarts in a loop (Linux / WSL)**: `docker compose logs clovance-apiservice` shows `Access to the path '/home/app/jwt.key' is denied`. The API image runs as the unprivileged `app` user (uid 1654) and the `data/jwt` bind mount keeps the host ownership, so the container cannot write its signing key. The installer now fixes this when it creates the directory; for an existing install run `chmod 0777 <install-dir>/data/jwt` (or `sudo chown -R 1654:1654 <install-dir>/data/jwt`) and `docker compose up -d`. Docker Desktop on Windows/macOS is not affected because it does not enforce ownership on bind mounts.
- **"Clovance did not start correctly"**: at least one container is not running. The installer waits up to 60 seconds for the stack to settle, so a container stuck in `restarting` fails the install instead of reporting success. Check `docker compose ps` and `docker compose logs` in the install directory.

## 📚 Related documentation

- [Docker Usage Guide](./DOCKER_USAGE.md) - Manual Docker Compose setup, ports, reverse proxy.
- [Docker Image Publishing](./DOCKER_PUBLISH.md) - Publishing and deployment guide.