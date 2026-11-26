---
title: Uso de las imágenes Docker de Clovance
description: Ejecuta Clovance con Docker Compose, configura los puertos y SMTP, y haz copias de seguridad de tus datos de PostgreSQL.
lang: es
translation: /DOCKER_USAGE.html
---

# Uso de las imágenes Docker de Clovance

Este documento muestra cómo usar las imágenes Docker publicadas en GitHub Container Registry (GHCR).

## 🐳 Docker Compose

Crea un archivo `.env`. SMTP es opcional: deja vacíos el host, usuario, contraseña y dirección de origen para ejecutar sin correo. En ese caso, Clovance no podrá enviar invitaciones ni correos de restablecimiento de contraseña. Si configuras SMTP, proporciona los cuatro valores, incluida la contraseña.

```
# Nombre de la imagen del contenedor para clovance-apiservice
CLOVANCE_APISERVICE_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-api:latest

# Puerto por defecto del contenedor para clovance-apiservice
CLOVANCE_APISERVICE_PORT=8080

# Nombre de la imagen del contenedor para clovance-frontend
CLOVANCE_FRONTEND_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-frontend:latest

# Parámetro frontend-base-url
FRONTEND_BASE_URL=http://localhost:7000

# Parámetro postgres-password
POSTGRES_PASSWORD=your_postgres_password

# Parámetro postgres-username
POSTGRES_USERNAME=your_postgres_username

# Configuración SMTP opcional. Deja vacíos el host, usuario, contraseña y
# dirección de origen para desactivar el correo. Si la activas, rellena los cuatro valores.
SMTP_FROM_ADDRESS=

# Parámetro smtp-from-name
SMTP_FROM_NAME=Clovance

# Parámetro smtp-host
SMTP_HOST=

# Parámetro smtp-password
SMTP_PASSWORD=

# Parámetro smtp-port
SMTP_PORT=587

# Parámetro smtp-username
SMTP_USERNAME=

# Parámetro volume-source-path
VOLUME_SOURCE_PATH=/home/docker/clovance
```

Usa el archivo Compose canónico, que también utilizan ambos instaladores:

- [Descargar `docker-compose.yml`](https://evaristocuesta.github.io/clovance/install/docker-compose.yml)
- O descárgalo desde una terminal:

  ```bash
  curl -fsSLo docker-compose.yml https://evaristocuesta.github.io/clovance/install/docker-compose.yml
  ```

  En PowerShell:

  ```powershell
  Invoke-WebRequest https://evaristocuesta.github.io/clovance/install/docker-compose.yml -OutFile docker-compose.yml
  ```

Mantén el archivo `.env` en el mismo directorio que `docker-compose.yml`.

Arranca la aplicación:

```bash
docker compose up -d
```

Detén la aplicación:

```bash
docker compose down
```

Para eliminar también el volumen de la base de datos:

```bash
docker compose down -v
```

---

## Puertos publicados y proxy inverso

Solo se publican dos puertos en el host. La API y PostgreSQL solo son accesibles a través de la red interna de Docker.

| Servicio | Puerto del host | Variable de dirección de bind | Valor por defecto |
|---|---|---|---|
| Frontend (Clovance) | `7000` | `CLOVANCE_BIND_ADDRESS` | `0.0.0.0` |
| Dashboard de Aspire | aleatorio (ver `docker ps`) | `CLOVANCE_DASHBOARD_BIND_ADDRESS` | `0.0.0.0` |

### Acceso directo por IP y puerto

Con los valores por defecto, Clovance está disponible en `http://<host-ip>:7000`. El tráfico es HTTP sin cifrar, así que úsalo en una red de confianza.

### Detrás de un proxy inverso con TLS

Para usar un nombre de dominio y un certificado, coloca un proxy inverso (nginx, Caddy, Traefik...) delante de Clovance y apúntalo al puerto `7000`. El proxy debe enviar las cabeceras `X-Forwarded-Proto` y `X-Forwarded-For`; de lo contrario, la cookie de refresco no se marca como `Secure`. Clovance solo confía en estas cabeceras cuando provienen de una dirección de red privada (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).

Si el proxy se ejecuta en el mismo host, cierra el acceso directo enlazando Clovance a la interfaz loopback y apunta el proxy a `127.0.0.1:7000`:

```
CLOVANCE_BIND_ADDRESS=127.0.0.1
```

Si el proxy se ejecuta en otra máquina, mantén el valor por defecto (o configura la IP LAN del host), porque el proxy debe llegar al puerto publicado a través de la red.

En ambos casos, no reenvíes el puerto `7000` en tu router. Solo el puerto del proxy (normalmente `443`) debería ser accesible desde internet.

### Dashboard de Aspire

El dashboard muestra la telemetría y el entorno de cada servicio. Pide un token de navegador que se imprime en los logs del contenedor (`docker logs <dashboard-container>`). Nunca lo expongas a internet. Para acceder solo desde el host, configura:

```
CLOVANCE_DASHBOARD_BIND_ADDRESS=127.0.0.1
```

Comprueba qué está publicado con `docker ps` o `docker compose config`.

---

## 🎯 Descargar una versión concreta

```bash
# Versiones estables
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:latest

# Preversiones
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta2
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:2.0.0-rc2
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-alpha3
```

> **Nota:** Las preversiones **no** actualizan las etiquetas `latest`, `1` ni `1.0`.

---

## 🧪 Ejecutar solo la API

```bash
docker run -d \
  --name clovance-api \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  -e ConnectionStrings__DefaultConnection="Host=localhost;Database=clovance;Username=postgres;Password=postgres" \
  ghcr.io/evaristocuesta/clovance/clovance-api:latest
```

---

## 🖥️ Ejecutar solo el frontend

```bash
docker run -d \
  --name clovance-frontend \
  -p 8000:8000 \
  -e API_URL=http://localhost:8080 \
  ghcr.io/evaristocuesta/clovance/clovance-frontend:latest
```

---

## 🔍 Inspeccionar las imágenes Docker

Mostrar información de la imagen:

```bash
docker inspect ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```

Mostrar las capas y el tamaño de la imagen:

```bash
docker history ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```

---

## 📊 Compatibilidad multiarquitectura

Las imágenes Docker se publican para varias arquitecturas:

- `linux/amd64` (x86_64)
- `linux/arm64` (Apple Silicon y servidores ARM)

Docker descarga automáticamente la imagen correcta para tu plataforma.

---

## 🚀 Ejemplo de GitHub Actions

Las imágenes Docker publicadas se pueden usar directamente en workflows de GitHub Actions.

{% raw %}
```yaml
- name: Pull Docker images
  run: |
    docker pull ghcr.io/evaristocuesta/clovance/clovance-api:${{ github.ref_name }}
    docker pull ghcr.io/evaristocuesta/clovance/clovance-frontend:${{ github.ref_name }}
```
{% endraw %}

---

## 📚 Documentación relacionada

- [Publicación de imágenes Docker](DOCKER_PUBLISH.es.html)
