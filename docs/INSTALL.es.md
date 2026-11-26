---
title: Instalar Clovance
description: Instala Clovance en Windows, Linux o macOS con los instaladores de un solo comando. Docker es el único requisito.
lang: es
translation: /INSTALL.html
---

# Instalar Clovance

Clovance incluye instaladores multiplataforma para Windows, Linux y macOS. Comprueban Docker, hacen algunas preguntas, generan la configuración, descargan las imágenes y arrancan la aplicación.

## 🚀 Instalación rápida

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/install.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/install.ps1 | iex
```

También puedes ejecutar los scripts directamente desde una copia local del repositorio:

```bash
# Linux / macOS
./docs/install/install.sh

# Windows
.\docs\install\install.ps1
```

## 📋 Requisitos

- Docker (Docker Desktop en Windows/macOS, o Docker Engine en Linux).
- El plugin Docker Compose v2 (`docker compose`, no el antiguo `docker-compose`).
- El daemon de Docker debe estar en ejecución.

El instalador verifica todo esto antes de hacer cualquier otra cosa.

## ⚙️ Parámetros de instalación

Durante la instalación se te pedirán los siguientes valores (los valores por defecto aparecen entre corchetes):

| Pregunta | Valor por defecto | Descripción |
|---|---|---|
| Directorio de instalación | `~/clovance` (Linux/macOS), `%USERPROFILE%\clovance` (Windows) | Dónde se guardan `.env`, `docker-compose.yml` y los datos. |
| Etiqueta de versión de la imagen | `latest` | Etiqueta de la imagen Docker que se descargará (p. ej. `1.0.0`). Nota: las etiquetas **no** incluyen una `v` inicial. |
| Puerto del host para el frontend | `7000` | Puerto del host expuesto para la interfaz de Clovance. |
| Puerto del contenedor de la API | `8080` | Puerto interno del servicio de API. |
| Dirección de bind (frontend) | `0.0.0.0` | Interfaz a la que se enlaza el frontend. Usa `127.0.0.1` para restringirlo a localhost. |
| Dirección de bind (dashboard) | `127.0.0.1` | Interfaz a la que se enlaza el dashboard de Aspire. |
| Usuario de PostgreSQL | `clovance` | Usuario de la base de datos. |
| Contraseña de PostgreSQL | *(generada automáticamente)* | Déjala vacía para generar una contraseña aleatoria. |
| Configurar SMTP | `No` (una configuración completa existente toma `Sí` por defecto) | Opcional. Si se desactiva, Clovance arranca sin envío de correos. |
| Host, puerto, usuario, contraseña y dirección de origen de SMTP | Obligatorios solo si SMTP está activado; el puerto por defecto es `587` | SMTP se usa para enviar invitaciones y correos de restablecimiento de contraseña. |
| Nombre del remitente SMTP | `Clovance` | Nombre para mostrar del remitente. Opcional. |
| URL base del frontend | `http://localhost:7000` | URL pública del frontend (la usa la API). |

Si eliges **No**, el instalador deja vacíos el host, usuario, contraseña y dirección de origen de SMTP. Clovance arrancará, pero no podrá enviar invitaciones ni correos de restablecimiento de contraseña. Puedes activar SMTP más adelante rellenando esos cuatro valores en `.env` y recreando el contenedor de la API. Si eliges **Sí**, el instalador exige la configuración SMTP, incluida una contraseña.

Los datos se guardan en `<install-dir>/data` (datos de Postgres y la clave JWT).

Si vuelves a ejecutar el instalador sobre una instalación existente, se usan los valores de `.env` como valores por defecto y se mantiene la contraseña actual de PostgreSQL (`POSTGRES_PASSWORD` solo se usa al crear la base de datos). Una configuración SMTP completa se considera activada por defecto; si está incompleta se avisa y se desactiva por defecto, salvo que elijas completarla.

## 🔄 Actualizar

Para actualizar a una nueva versión:

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/update.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/update.ps1 | iex
```

O, desde una copia local del repositorio:

```bash
# Linux / macOS
./docs/install/update.sh

# Windows
.\docs\install\update.ps1
```

Ambos scripts llaman a `install.sh update` / `install.ps1 update`, así que son equivalentes:

```bash
./install.sh update      # Linux / macOS
.\install.ps1 update     # Windows
```

Se te pedirá el directorio de instalación y la nueva etiqueta de versión de la imagen. El script hace una copia de `.env` en `.env.bak`, actualiza las etiquetas de imagen, descarga las nuevas imágenes y recrea los contenedores. Falla con un error (y conserva `.env.bak`) si no se pueden descargar las imágenes o si los contenedores no vuelven a arrancar.

## 🗑️ Desinstalar

**Linux / macOS:**

```bash
curl -fsSL https://evaristocuesta.github.io/clovance/install/uninstall.sh | sh
```

**Windows (PowerShell):**

```powershell
irm https://evaristocuesta.github.io/clovance/install/uninstall.ps1 | iex
```

O, desde una copia local del repositorio:

```bash
# Linux / macOS
./docs/install/uninstall.sh

# Windows
.\docs\install\uninstall.ps1
```

Ambos scripts llaman a `install.sh uninstall` / `install.ps1 uninstall`, así que son equivalentes:

```bash
./install.sh uninstall      # Linux / macOS
.\install.ps1 uninstall     # Windows
```

El script detiene y elimina los contenedores y luego pregunta:

1. **¿Eliminar los volúmenes de datos (postgres + jwt)?** — responde `y` para borrar la base de datos y la clave JWT.
2. **¿Eliminar los archivos de configuración generados (.env, docker-compose.yml)?** — responde `y` para limpiar la configuración.

No se elimina nada si antes no se pueden detener los contenedores, y si Docker no está en ejecución el script aborta con un error en lugar de fingir que ha funcionado.

Las imágenes Docker **no** se eliminan. Para eliminarlas también:

```bash
docker image rm ghcr.io/evaristocuesta/clovance/clovance-api:latest ghcr.io/evaristocuesta/clovance/clovance-frontend:latest
```

En Linux/macOS, si el directorio de datos lo creó el contenedor (con propietario root), el script intentará usar `sudo` automáticamente; si falla, ejecuta manualmente `sudo rm -rf <install-dir>/data`.

## 🛠️ Solución de problemas

- **Docker no está en ejecución**: inicia Docker Desktop / el daemon de Docker y vuelve a intentarlo. Los instaladores verifican el daemon antes de escribir cualquier configuración y salen con un error si está caído.
- **Falta Compose v2**: actualiza Docker o instala el plugin Compose.
- **Permiso denegado al eliminar los datos (Linux)**: usa `sudo rm -rf <install-dir>/data`.
- **Puerto ya en uso**: elige otro puerto de frontend durante la instalación o detén el servicio que lo esté usando.
- **La API se reinicia en bucle (Linux / WSL)**: `docker compose logs clovance-apiservice` muestra `Access to the path '/home/app/jwt.key' is denied`. La imagen de la API se ejecuta con el usuario sin privilegios `app` (uid 1654) y el bind mount `data/jwt` conserva el propietario del host, por lo que el contenedor no puede escribir su clave de firma. El instalador ya lo corrige cuando crea el directorio; para una instalación existente ejecuta `chmod 0777 <install-dir>/data/jwt` (o `sudo chown -R 1654:1654 <install-dir>/data/jwt`) y `docker compose up -d`. Docker Desktop en Windows/macOS no se ve afectado porque no aplica el propietario en los bind mounts.
- **La web carga pero todas las llamadas a la API devuelven `502 Bad Gateway`**: `docker compose logs clovance-frontend` muestra `connect() failed (111: Connection refused)` contra una IP que ya no pertenece al contenedor de la API. Compose asigna una IP nueva al contenedor recreado, mientras que nginx resolvió el nombre `clovance-apiservice` solo una vez, al arrancar. Reinicia solo el frontend (`docker compose restart clovance-frontend`) en lugar de redesplegar; las imágenes actuales del frontend resuelven el nombre en cada petición, así que el problema solo afecta a las antiguas.
- **"Clovance did not start correctly"**: al menos un contenedor nunca llegó a estar listo. El instalador espera a que todos los servicios estén `healthy` (hasta 5 minutos, ajustable con `CLOVANCE_VERIFY_TIMEOUT`), así que un contenedor atascado en `restarting` o `unhealthy` hace que la instalación falle en lugar de informar de éxito. Revisa `docker compose ps` y `docker compose logs` en el directorio de instalación.

## 📚 Documentación relacionada

- [Guía de uso con Docker](./DOCKER_USAGE.es.html) - Configuración manual con Docker Compose, puertos y proxy inverso.
- [Publicación de imágenes Docker](./DOCKER_PUBLISH.es.html) - Guía de publicación y despliegue.
