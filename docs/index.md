# Clovance

**Your personal finances, on your own server.** Open source, self-hosted, installable with a single command.

Clovance helps you stay in control of your money without giving up your privacy: record expenses and income, manage multiple accounts, transfer between them, track loans, and analyze your spending patterns. **Your data stays on your server**, not in someone else's cloud, and **there's no monthly subscription**.

📖 [Leer en español](./index.es.md)

![Clovance](./images/clovance-screenshot-01.jpg)

## ✨ What can you do with Clovance?

- 📊 **A complete view of your finances**: balance per account, movements, and spending/income statistics.
- 💸 **Record expenses and income** with a clear history.
- 🏦 **Manage multiple accounts** (cash, banks, cards, savings) in one place.
- 🔁 **Transfers between accounts** without duplicating movements.
- 💳 **Track loans** and their evolution.
- 📈 **Statistics and cash flow** to understand where your money goes.
- 🌍 **Interface in English and Spanish.**
- 🔒 **Secure authentication** and data under your control.

![Clovance](./images/clovance-screenshot-02.jpg)
![Clovance](./images/clovance-screenshot-03.jpg)

## 🔒 Privacy & self-hosting

- Your financial data **never leaves your environment**.
- **No third-party account**, no telemetry, no ads.
- **No subscription**: once installed, it's yours.
- Open source (Apache 2.0): audit it, modify it, contribute to it.

## 🚀 Install with one command

You only need Docker.

**Linux / macOS:**
```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

The scripts also support `uninstall` and `update`. Full guide: [Installation Guide](./INSTALL.md). Manual setup: [Docker Usage Guide](./DOCKER_USAGE.md).

## ❓ FAQ

**Do I need to know how to code?** No. Just install Docker and run the command.

**Can I use it without email?** Yes. Email is optional; without SMTP, invitations and password resets aren't sent, but the app works.

**Where is my data stored?** In a PostgreSQL database running on your own server/container.

**How do I back up?** Back up the PostgreSQL data volume (see [Docker Usage Guide](./DOCKER_USAGE.md)).

**Is it free?** Yes, open source under Apache 2.0. No license fees.

## 🤝 Community

Want to help? Read the [Contributing Guide](https://github.com/evaristocuesta/clovance/blob/main/CONTRIBUTING.md). Ideas, bugs, and improvements in the [Issues](https://github.com/evaristocuesta/clovance/issues).

## 📄 License

Apache License 2.0. See [LICENSE](https://github.com/evaristocuesta/clovance/blob/main/LICENSE.md).

---

<details markdown="1">
<summary><strong>🛠️ For developers</strong></summary>

Stack: .NET 10, .NET Aspire, Angular 22, PostgreSQL, Tailwind/Flowbite.

Local development:
```bash
cd api/aspire/Clovance.AppHost
dotnet run
```

Frontend build:
```bash
cd frontend
pnpm install --frozen-lockfile
pnpm build
```

Tests: unit (`api/tests/Clovance.UnitTests`), integration with Docker (`api/tests/Clovance.IntegrationTests`), frontend (`pnpm test`).

Publish a version: `.\scripts\publish-version.ps1 -Version "1.0.0"`.

Docker images: `ghcr.io/evaristocuesta/clovance/clovance-api` and `.../clovance-frontend`.

More: [Docker Publishing](./DOCKER_PUBLISH.md) · [Versioning](./VERSIONING_EXAMPLES.md).

</details>