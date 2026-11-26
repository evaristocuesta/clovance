---
title: Publicar imágenes Docker
description: Cómo publica Clovance las imágenes Docker en GitHub Container Registry (GHCR) con GitHub Actions.
lang: es
translation: /DOCKER_PUBLISH.html
---

# Publicar imágenes Docker con GitHub Actions

Este documento explica cómo funciona la publicación automática de imágenes Docker en GitHub Container Registry (GHCR).

## 🚀 Proceso de publicación

### Automático con script (recomendado)

Usa el script de PowerShell incluido para crear y publicar nuevas versiones de forma segura:

```powershell
# Desde la raíz del repositorio

# Versión de producción
.\scripts\publish-version.ps1 -Version "1.0.0"

# Preversión (beta, rc, alpha)
.\scripts\publish-version.ps1 -Version "1.0.0-beta1"
.\scripts\publish-version.ps1 -Version "2.0.0-rc2"
.\scripts\publish-version.ps1 -Version "1.0.0-alpha1"

# Previsualizar lo que ocurriría sin ejecutarlo (dry run)
.\scripts\publish-version.ps1 -Version "1.0.0" -DryRun
```

El script verifica automáticamente:

- ✅ Formato de versión correcto (`X.Y.Z` o `X.Y.Z-prerelease`)
- ✅ Sin cambios sin commitear
- ✅ Tu rama local está al día con el remoto
- ✅ La etiqueta no existe todavía

### Manual

También puedes crear las etiquetas manualmente:

```bash
# Crear una etiqueta de versión de producción
git tag v1.0.0

# Crear una etiqueta de preversión
git tag v1.0.0-beta1

# Subir la etiqueta a GitHub
git push origin v1.0.0
# o
git push origin v1.0.0-beta1
```

### Qué ocurre automáticamente

Esto dispara el workflow de GitHub Actions, que:

1. Compila las imágenes Docker de la API y del frontend.
2. Las etiqueta con varias etiquetas de imagen Docker (nota: las etiquetas de imagen nunca usan el prefijo `v`):
   - `1.0.0` (versión completa)
   - `1.0` (mayor.menor)
   - `1` (mayor)
   - `latest` (solo versiones estables)
   - `sha-<sha>` (SHA corto del commit)
3. Las publica en `ghcr.io/evaristocuesta/clovance/`.
4. Genera una atestación de procedencia.

La etiqueta Git (`v1.0.0`) es la única etiqueta Git que se crea; las etiquetas anteriores pertenecen a las imágenes Docker.

### Imágenes publicadas

- **API**: `ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0`
- **Frontend**: `ghcr.io/evaristocuesta/clovance/clovance-frontend:1.0.0`

## 📦 Estructura de etiquetas

El workflow genera automáticamente varias etiquetas para cada versión.

### Versiones de producción

```
Etiqueta Git v1.2.3 → etiquetas de imagen Docker generadas:
  - 1.2.3           (versión completa)
  - 1.2             (mayor.menor)
  - 1               (mayor)
  - latest          (solo versiones estables)
  - sha-abc1234     (SHA corto del commit)
```

### Preversiones (beta, rc, alpha)

```
Etiqueta Git v1.2.3-beta1 → etiquetas de imagen Docker generadas:
  - 1.2.3-beta1     (versión completa)
  - sha-abc1234     (SHA corto del commit)

⚠️ Las preversiones NO actualizan:
  - mayor.menor (1.2)
  - mayor (1)
  - latest
```

Esto garantiza que las versiones preliminares no sobrescriban las versiones estables de producción.

## 🔧 Desarrollo local con Aspire

### Desarrollo local

Para ejecutar la aplicación localmente con Aspire:

```bash
cd api/aspire/Clovance.AppHost
dotnet run
```

Esto usa `appsettings.Development.json` y **no** intenta publicar contenedores.

### Generar manifiestos de despliegue

Aspire puede generar artefactos de despliegue a partir del modelo de la aplicación (Docker Compose, Kubernetes, etc.) que hacen referencia a las imágenes publicadas en GHCR. A partir de Aspire 17, la publicación se realiza a través de la CLI de Aspire; `dotnet run --operation publish` se rechaza:

```bash
# Generar artefactos de despliegue (escribe en ./aspire-output)
cd api/aspire/Clovance.AppHost
aspire publish -e Production

# O elegir otro directorio de salida
aspire publish -e Production -o ./manifests
```

Esto genera archivos de despliegue listos para usar con las imágenes publicadas en GHCR.

## 🐳 Probar builds locales

### Servicio de API

```bash
# Desde la raíz del repositorio
docker build -t clovance-api:local -f api/src/Clovance.ApiService/Dockerfile .
docker run -p 8080:8080 clovance-api:local
```

### Frontend

```bash
# Desde el directorio del frontend
cd frontend
docker build -t clovance-frontend:local .
docker run -p 8000:8000 clovance-frontend:local
```

## 🔐 Permisos de GHCR

Las imágenes se publican como públicas por defecto. Para cambiar su visibilidad:

1. Ve a https://github.com/evaristocuesta?tab=packages
2. Busca el paquete (`clovance-api` o `clovance-frontend`)
3. Abre **Package settings**
4. Cambia la visibilidad a **Public** o **Private**

## 📋 Requisitos del workflow

El workflow requiere los siguientes permisos (ya configurados):

- `contents: read` - Para clonar el repositorio
- `packages: write` - Para publicar en GHCR

Usa automáticamente {% raw %}`${{ secrets.GITHUB_TOKEN }}`{% endraw %}, que GitHub genera para cada ejecución del workflow.

## 🔄 Versionado semántico

Se recomienda seguir [Semantic Versioning](https://semver.org/):

- **MAJOR** (`v1.0.0` → `v2.0.0`): Cambios incompatibles en la API
- **MINOR** (`v1.0.0` → `v1.1.0`): Nueva funcionalidad compatible hacia atrás
- **PATCH** (`v1.0.0` → `v1.0.1`): Corrección de errores
- **PRE-RELEASE** (`v1.0.0-beta1`): Versiones preliminares antes del lanzamiento oficial

### Ejemplos de versionado

```bash
# Desarrollo y pruebas
git tag v1.0.0-alpha && git push origin v1.0.0-alpha    # Versión muy temprana
git tag v1.0.0-beta1 && git push origin v1.0.0-beta1  # Primera beta
git tag v1.0.0-beta2 && git push origin v1.0.0-beta2  # Segunda beta
git tag v1.0.0-rc1 && git push origin v1.0.0-rc1      # Release candidate

# Producción
git tag v1.0.0 && git push origin v1.0.0  # Lanzamiento inicial
git tag v1.0.1 && git push origin v1.0.1  # Corrección de bug
git tag v1.1.0 && git push origin v1.1.0  # Nueva funcionalidad
git tag v2.0.0 && git push origin v2.0.0  # Cambio incompatible
```

## 🚨 Solución de problemas

### ¿Cuándo debo usar preversiones?

Usa preversiones para:

- ✅ Probar nuevas funcionalidades antes del lanzamiento
- ✅ Versiones beta públicas para primeros usuarios
- ✅ Candidatas a versión (release candidates) antes de un lanzamiento final
- ✅ Versiones alpha durante el desarrollo temprano

**NO uses preversiones para:**

- ❌ Versiones estables de producción
- ❌ Hotfixes urgentes (usa versiones de producción)

### Usar una preversión en producción

Si necesitas usar una preversión concreta:

```yaml
# docker-compose.yml
services:
  api:
    image: ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta1
```

```bash
# Descargar la imagen
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta1
```

### El workflow falla con «permission denied»

Verifica que el repositorio tenga activados los permisos de **Read and write** para GitHub Actions:

1. **Settings → Actions → General**
2. **Workflow permissions → Read and write permissions**

### Las imágenes no aparecen en GHCR

Puede tardar unos minutos en aparecer. Comprueba:

1. Que el workflow terminó correctamente: https://github.com/evaristocuesta/clovance/actions
2. Que los paquetes están disponibles en: https://github.com/evaristocuesta?tab=packages

### Quiero cambiar el registro

Edita `.github/workflows/publish-images.yml` y cambia:

```yaml
env:
  REGISTRY: ghcr.io  # Cambia a docker.io, quay.io, etc.
```

Actualiza también `appsettings.Production.json`:

```json
{
  "Parameters": {
    "container-registry": "docker.io/your-username/clovance"
  }
}
```

## 📚 Referencias

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [.NET Aspire Deployment](https://learn.microsoft.com/en-us/dotnet/aspire/deployment/overview)
- [Docker Build Push Action](https://github.com/marketplace/actions/build-and-push-docker-images)
