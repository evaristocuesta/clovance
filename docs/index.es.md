---
layout: home
title: Clovance
description: Clovance es una app de finanzas personales self-hosted y open source. Controla gastos, ingresos, cuentas, transferencias y préstamos con tus datos en tu propio servidor.
lang: es
translation: /
tagline: Tus finanzas personales, en tu propio servidor.
hero_sub: Registra gastos e ingresos, gestiona varias cuentas, transfiere entre ellas, controla préstamos y entiende a dónde va tu dinero, sin renunciar a tu privacidad.
---

Clovance te ayuda a llevar el control de tu dinero sin renunciar a tu privacidad: registra gastos e ingresos, gestiona varias cuentas, transfiere entre ellas, controla préstamos y analiza tus patrones de gasto. **Tus datos se quedan en tu servidor**, no en la nube de nadie, y **no hay suscripción mensual**.

![Vista de transacciones de Clovance](./images/clovance-screenshot-01.jpg)

## ✨ ¿Qué puedes hacer con Clovance?

- 📊 **Visión completa de tus finanzas**: saldo por cuenta, movimientos y estadísticas de gasto/ingreso.
- 💸 **Registrar gastos e ingresos** con historial claro y categorizado.
- 🏦 **Gestionar varias cuentas** (efectivo, bancos, tarjetas, ahorro) en un solo lugar.
- 🔁 **Transferencias entre cuentas** sin duplicar movimientos.
- 💳 **Controlar préstamos** y su evolución.
- 📈 **Estadísticas y flujos de caja** para entender a dónde va tu dinero.
- 🌍 **Interfaz en inglés y español.**
- 🔒 **Autenticación segura** (JWT) y datos bajo tu control.

![Panel de resumen de Clovance](./images/clovance-screenshot-02.jpg)
![Flujo de caja y ranking de cuentas de Clovance](./images/clovance-screenshot-03.jpg)

## 🔒 Privacidad y self-hosting

- Tus datos financieros **nunca salen de tu entorno**.
- **Sin cuenta en servicios de terceros**, sin telemetría, sin publicidad.
- **Sin suscripción**: una vez instalado, es tuyo.
- Código abierto (Apache 2.0): puedes auditarlo, modificarlo y contribuir.

## 🚀 Instalación en un comando

Solo necesitas Docker.

**Linux / macOS:**
```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

Los scripts también soportan `uninstall` y `update`. Guía completa: [Guía de instalación](./INSTALL.es.html). Configuración manual: [Guía de uso con Docker](./DOCKER_USAGE.es.html).

## ❓ Preguntas frecuentes

**¿Necesito saber programar?** No. Solo instalar Docker y ejecutar el comando.

**¿Puedo usarlo sin email?** Sí. El email es opcional; sin SMTP no se envían invitaciones ni restablecimiento de contraseña, pero la app funciona.

**¿Dónde se guardan mis datos?** En una base de datos PostgreSQL que corre en tu propio servidor/contenedor.

**¿Cómo hago copias de seguridad?** Respaldando el volumen de datos de PostgreSQL (ver [Guía de uso con Docker](./DOCKER_USAGE.es.html)).

**¿Es gratis?** Sí, open source bajo Apache 2.0. Sin costes de licencia.

## 🤝 Comunidad

¿Quieres ayudar? Lee la [Contributing Guide](https://github.com/evaristocuesta/clovance/blob/main/CONTRIBUTING.md). Ideas, bugs y mejoras en los [Issues](https://github.com/evaristocuesta/clovance/issues).

## 📄 Licencia

Apache License 2.0. Ver [LICENSE](https://github.com/evaristocuesta/clovance/blob/main/LICENSE.md).

---

<details markdown="1">
<summary><strong>🛠️ Para desarrolladores</strong></summary>

Stack: .NET 10, .NET Aspire, Angular 22, PostgreSQL, Tailwind/Flowbite.

Desarrollo local:
```bash
cd api/aspire/Clovance.AppHost
dotnet run
```

Build frontend:
```bash
cd frontend
pnpm install --frozen-lockfile
pnpm build
```

Tests: unit (`api/tests/Clovance.UnitTests`), integración con Docker (`api/tests/Clovance.IntegrationTests`), frontend (`pnpm test`).

Publicar versión: `.\scripts\publish-version.ps1 -Version "1.0.0"`.

Imágenes Docker: `ghcr.io/evaristocuesta/clovance/clovance-api` y `.../clovance-frontend`.

Más: [Publicación de Docker](./DOCKER_PUBLISH.es.html) · [Versionado](./VERSIONING_EXAMPLES.es.html).

</details>