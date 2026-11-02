<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./docs/images/logo-full-light.svg">
  <img alt="Clovance" src="./docs/images/logo-full-dark.svg">
</picture>

# Clovance

**Your personal finances, on your own server.** Open source, self-hosted, installable with a single command.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE.md)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](docs/DOCKER_USAGE.md)
[![Self-hosted](https://img.shields.io/badge/Self--hosted-yes-2ea44f)](#)
[![Languages](https://img.shields.io/badge/UI-English%20%7C%20Espa%C3%B1ol-informational)](#)

Clovance helps you stay in control of your money without giving up your privacy: record expenses and income, manage multiple accounts, transfer between them, track loans, and analyze your spending patterns. **Your data stays on your server**, not in someone else's cloud, and **there's no monthly subscription**.

📖 [Leer en español](README.es.md)

![Clovance](docs/images/clovance-screenshot-01.jpg)

## ✨ What can you do with Clovance?

- 📊 **A complete view of your finances**: balance per account, movements, and spending/income statistics.
- 💸 **Record expenses and income** with a clear history.
- 🏦 **Manage multiple accounts** (cash, banks, cards, savings) in one place.
- 🔁 **Transfers between accounts** without duplicating movements.
- 💳 **Track loans** and their evolution.
- 📈 **Statistics and cash flow** to understand where your money goes.
- 🌍 **Interface in English and Spanish.**
- 🔒 **Secure authentication** (JWT) and data under your control.

## 🔒 Privacy & self-hosting

Unlike cloud-based finance apps, Clovance runs **on your own machine or server**:

- Your financial data **never leaves your environment**.
- **No third-party account**, no telemetry, no ads.
- **No subscription**: once installed, it's yours.
- Open source (Apache 2.0): audit it, modify it, contribute to it.

## 🚀 Install with one command

You only need Docker. The installer checks Docker, asks a few questions, generates the configuration, pulls the images, and starts the app.

**Linux / macOS:**
```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

The scripts also support `uninstall` and `update`. Full guide: [Installation Guide](docs/INSTALL.md). Manual setup with Docker Compose: [Docker Usage Guide](docs/DOCKER_USAGE.md).

## 🖼️ Screenshots

![Clovance](docs/images/clovance-screenshot-02.jpg)
![Clovance](docs/images/clovance-screenshot-03.jpg)

## ❓ FAQ

**Do I need to know how to code?** No. Just install Docker and run the command.

**Can I use it without email?** Yes. Email is optional; without SMTP, invitations and password resets aren't sent, but the app works.

**Where is my data stored?** In a PostgreSQL database running on your own server/container.

**How do I back up?** Back up the PostgreSQL data volume (see [Docker Usage Guide](docs/DOCKER_USAGE.md)).

**Is it free?** Yes, open source under Apache 2.0. No license fees.

## 🤝 Community & contributions

Want to help? Read the [Contributing Guide](CONTRIBUTING.md). Ideas, bugs, and improvements are welcome in the [Issues](https://github.com/evaristocuesta/clovance/issues).

## 📄 License

Apache License 2.0. See [LICENSE](LICENSE.md).

---

<details>
<summary><strong>🛠️ For developers (stack, build & tests)</strong></summary>

Clovance is built with .NET 10, .NET Aspire, Angular 22, PostgreSQL, and Tailwind/Flowbite.

**Project structure:**
```
Clovance/
├── api/                          # .NET backend
│   ├── aspire/                   # Aspire orchestration
│   │   ├── Clovance.AppHost/
│   │   └── Clovance.ServiceDefaults/
│   ├── src/Clovance.ApiService/  # REST API
│   └── tests/
│       ├── Clovance.UnitTests/
│       └── Clovance.IntegrationTests/
├── frontend/                     # Angular
├── scripts/                      # Utilities
└── docs/                         # Documentation
```

**Local development:**
```bash
cd api/aspire/Clovance.AppHost
dotnet run
```
Starts the API, frontend, PostgreSQL (pgWeb), and the Aspire dashboard.

**Frontend build:**
```bash
cd frontend
pnpm install --frozen-lockfile
pnpm build
```

**Tests:**
- Unit: `dotnet test` in `api/tests/Clovance.UnitTests`
- Integration (requires Docker): `dotnet test` in `api/tests/Clovance.IntegrationTests`
- Frontend: `pnpm test --watch=false --providers-file=src/testing/ci-test.providers.ts`

**Publish a new version:**
```powershell
.\scripts\publish-version.ps1 -Version "1.0.0"
```
Creates a tag and triggers the GitHub Actions workflow that publishes Docker images to GHCR.

**Docker images:**
- `ghcr.io/evaristocuesta/clovance/clovance-api`
- `ghcr.io/evaristocuesta/clovance/clovance-frontend`

More details: [Docker Publishing](docs/DOCKER_PUBLISH.md) · [Versioning](docs/VERSIONING_EXAMPLES.md)

</details>