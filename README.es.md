<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./docs/images/logo-full-light.svg">
  <img alt="Clovance" src="./docs/images/logo-full-dark.svg">
</picture>

# Clovance

**Tus finanzas personales, en tu propio servidor.** Open source, self-hosted, instalación en un solo comando.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE.md)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](docs/DOCKER_USAGE.md)
[![Self-hosted](https://img.shields.io/badge/Self--hosted-yes-2ea44f)](#)
[![Languages](https://img.shields.io/badge/UI-English%20%7C%20Espa%C3%B1ol-informational)](#)

Clovance te ayuda a llevar el control de tu dinero sin renunciar a tu privacidad: registra gastos e ingresos, gestiona varias cuentas, transfiere entre ellas, controla préstamos y analiza tus patrones de gasto. **Tus datos se quedan en tu servidor**, no en la nube de nadie, y **no hay suscripción mensual**.

📖 [Read in English](README.md)

![Clovance](docs/images/clovance-screenshot-01.jpg)

## ✨ ¿Qué puedes hacer con Clovance?

- 📊 **Visión completa de tus finanzas**: saldo por cuenta, movimientos y estadísticas de gasto/ingreso.
- 💸 **Registrar gastos e ingresos** con historial claro y categorizado.
- 🏦 **Gestionar varias cuentas** (efectivo, bancos, tarjetas, ahorro) en un solo lugar.
- 🔁 **Transferencias entre cuentas** sin duplicar movimientos.
- 💳 **Controlar préstamos** y su evolución.
- 📈 **Estadísticas y flujos de caja** para entender a dónde va tu dinero.
- 🌍 **Interfaz en inglés y español.**
- 🔒 **Autenticación segura** (JWT) y datos bajo tu control.

## 🔒 Privacidad y self-hosting

A diferencia de apps financieras en la nube, Clovance se ejecuta **en tu propia máquina o servidor**:

- Tus datos financieros **nunca salen de tu entorno**.
- **Sin cuenta en servicios de terceros**, sin telemetría, sin publicidad.
- **Sin suscripción**: una vez instalado, es tuyo.
- Código abierto (Apache 2.0): puedes auditarlo, modificarlo y contribuir.

## 🚀 Instalación en un comando

Solo necesitas Docker. El instalador comprueba Docker, te hace unas preguntas, genera la configuración, descarga las imágenes y arranca la app.

**Linux / macOS:**
```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

Los scripts también soportan `uninstall` y `update`. Guía completa: [Installation Guide](docs/INSTALL.md). Configuración manual con Docker Compose: [Docker Usage Guide](docs/DOCKER_USAGE.md).

## 🖼️ Capturas

![Clovance](docs/images/clovance-screenshot-02.jpg)
![Clovance](docs/images/clovance-screenshot-03.jpg)

## ❓ Preguntas frecuentes

**¿Necesito saber programar para usarlo?** No. Solo instalar Docker y ejecutar el comando.

**¿Puedo usarlo sin email?** Sí. El email es opcional; sin SMTP no se envían invitaciones ni restablecimiento de contraseña, pero la app funciona.

**¿Dónde se guardan mis datos?** En una base de datos PostgreSQL que corre en tu propio servidor/contenedor.

**¿Cómo hago copias de seguridad?** Respaldando el volumen de datos de PostgreSQL (ver [Docker Usage Guide](docs/DOCKER_USAGE.md)).

**¿Es gratis?** Sí, open source bajo Apache 2.0. Sin costes de licencia.

## 🤝 Comunidad y contribuciones

¿Quieres ayudar? Lee la [Contributing Guide](CONTRIBUTING.md). Ideas, bugs y mejoras son bienvenidas en los [Issues](https://github.com/evaristocuesta/clovance/issues).

## 📄 Licencia

Apache License 2.0. Ver [LICENSE](LICENSE.md).

---

<details>
<summary><strong>🛠️ Para desarrolladores (stack, build y tests)</strong></summary>

Clovance está construido con .NET 10, .NET Aspire, Angular 22, PostgreSQL y Tailwind/Flowbite.

**Estructura del proyecto:**
```
Clovance/
├── api/                          # Backend .NET
│   ├── aspire/                   # Orquestación Aspire
│   │   ├── Clovance.AppHost/
│   │   └── Clovance.ServiceDefaults/
│   ├── src/Clovance.ApiService/  # API REST
│   └── tests/
│       ├── Clovance.UnitTests/
│       └── Clovance.IntegrationTests/
├── frontend/                     # Angular
├── scripts/                      # Utilidades
└── docs/                         # Documentación
```

**Desarrollo local:**
```bash
cd api/aspire/Clovance.AppHost
dotnet run
```
Arranca API, frontend, PostgreSQL (pgWeb) y el dashboard de Aspire.

**Build frontend:**
```bash
cd frontend
pnpm install --frozen-lockfile
pnpm build
```

**Tests:**
- Unit: `dotnet test` en `api/tests/Clovance.UnitTests`
- Integración (requiere Docker): `dotnet test` en `api/tests/Clovance.IntegrationTests`
- Frontend: `pnpm test --watch=false --providers-file=src/testing/ci-test.providers.ts`

**Publicar nueva versión:**
```powershell
.\scripts\publish-version.ps1 -Version "1.0.0"
```
Crea un tag y dispara el workflow de GitHub Actions que publica las imágenes Docker en GHCR.

**Imágenes Docker:**
- `ghcr.io/evaristocuesta/clovance/clovance-api`
- `ghcr.io/evaristocuesta/clovance/clovance-frontend`

Más detalles: [Docker Publishing](docs/DOCKER_PUBLISH.md) · [Versioning](docs/VERSIONING_EXAMPLES.md)

</details>
"