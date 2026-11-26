---
title: Ejemplos de publicación de versiones
description: Ejemplos prácticos para publicar versiones de Clovance, etiquetas Git y etiquetas de imágenes Docker.
lang: es
translation: /VERSIONING_EXAMPLES.html
---

# Ejemplos de publicación de versiones

Este documento ofrece ejemplos prácticos de cómo publicar distintos tipos de versiones.

> **En un lanzamiento intervienen dos tipos de etiquetas — no las mezcles:**
>
> - **Etiqueta Git** (p. ej. `v1.0.0`): la crea `scripts/publish-version.ps1`. Marca la versión en Git y dispara el workflow `publish-images.yml`. El script crea siempre exactamente **una** etiqueta Git: la completa `vX.Y.Z`. **No** hay etiquetas Git como `v1.0`, `v1` o `latest`.
> - **Etiquetas de imagen Docker** (p. ej. `1.0.0`, `1.0`, `1`, `latest`): las crea el workflow en GHCR para `clovance-api` y `clovance-frontend`. Las etiquetas de imagen nunca usan el prefijo `v`. Cada lanzamiento recibe además una etiqueta `sha-<commit>`.

## 🚀 Escenarios habituales

### Escenario 1: Primera versión

Ya estás listo para publicar la versión 1.0.0 de tu aplicación:

```powershell
# Verifica que todo está commiteado
git status

# Crea y publica la versión
.\scripts\publish-version.ps1 -Version "1.0.0"
```

**Resultado:**

- Etiqueta Git creada: `v1.0.0` (dispara el workflow de publicación)
- Etiquetas de imagen Docker publicadas en GHCR: `1.0.0`, `1.0`, `1`, `latest`, `sha-<commit>`

---

### Escenario 2: Corrección de un bug

Has encontrado un bug en producción y necesitas publicar un parche:

```powershell
# Crea la versión de parche
.\scripts\publish-version.ps1 -Version "1.0.1"
```

**Resultado:**

- Etiqueta Git creada: `v1.0.1`
- Etiquetas de imagen Docker: `1.0.1`, `1.0` (actualizada), `1` (actualizada), `latest` (actualizada), `sha-<commit>`
- Los usuarios que descarguen la etiqueta `1.0` recibirán la corrección automáticamente

---

### Escenario 3: Nueva funcionalidad compatible

Has añadido una funcionalidad nueva compatible hacia atrás:

```powershell
.\scripts\publish-version.ps1 -Version "1.1.0"
```

**Resultado:**

- Etiqueta Git creada: `v1.1.0`
- Etiquetas de imagen Docker: `1.1.0`, `1.1`, `1` (actualizada), `latest` (actualizada), `sha-<commit>`

---

### Escenario 4: Pruebas beta

Quieres que algunos usuarios prueben una nueva funcionalidad antes del lanzamiento oficial:

```powershell
# Primera beta
.\scripts\publish-version.ps1 -Version "2.0.0-beta1"
```

**Resultado:**

- Etiqueta Git creada: `v2.0.0-beta1`
- Etiquetas de imagen Docker: `2.0.0-beta1`, `sha-<commit>` (**solo** estas dos)
- `latest`, `2` y `2.0` **no** se actualizan (producción sigue en v1.x.x): las preversiones nunca tocan las etiquetas de imagen mutables

**Los usuarios de la beta pueden usar:**

```yaml
services:
  api:
    image: ghcr.io/evaristocuesta/clovance/clovance-api:2.0.0-beta1
```

---

### Escenario 5: Release candidate

La beta fue bien, así que creas un release candidate:

```powershell
.\scripts\publish-version.ps1 -Version "2.0.0-rc1"
```

Después de validar el RC, publica la versión final:

```powershell
.\scripts\publish-version.ps1 -Version "2.0.0"
```

**Resultado:**

- Etiqueta Git creada: `v2.0.0`
- Etiquetas de imagen Docker: `2.0.0`, `2.0`, `2`, `sha-<commit>`, y ahora `latest`, `2` y `2.0` apuntan a la versión estable 2.0.0.
- Es una versión con cambios incompatibles, así que los usuarios deben migrar explícitamente.

---

### Escenario 6: Hotfix urgente

Un bug crítico en producción necesita una corrección inmediata:

```powershell
# Crea una rama de hotfix desde la etiqueta de producción
git checkout v1.1.0
git checkout -b hotfix/critical-bug

# Aplica la corrección
git add .
git commit -m "fix: critical security issue"

# Fusiona en main y crea la versión
git checkout main
git merge hotfix/critical-bug
git push

# Publica el hotfix
.\scripts\publish-version.ps1 -Version "1.1.1"
```

---

### Escenario 7: Versión alpha para desarrollo interno

Una versión muy temprana pensada solo para el equipo de desarrollo:

```powershell
.\scripts\publish-version.ps1 -Version "3.0.0-alpha1"
```

**Uso interno:**

```bash
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:3.0.0-alpha1
```

---

## 🔄 Flujo de desarrollo completo

Ejemplo de un ciclo de publicación completo desde alpha hasta producción:

```powershell
# 1. Desarrollo inicial
.\scripts\publish-version.ps1 -Version "2.0.0-alpha1"

# 2. Primera versión de prueba pública
.\scripts\publish-version.ps1 -Version "2.0.0-beta1"

# 3. Segunda beta con correcciones
.\scripts\publish-version.ps1 -Version "2.0.0-beta2"

# 4. Release candidate
.\scripts\publish-version.ps1 -Version "2.0.0-rc1"

# 5. Versión final
.\scripts\publish-version.ps1 -Version "2.0.0"

# 6. Hotfix si es necesario
.\scripts\publish-version.ps1 -Version "2.0.1"

# 7. Nueva funcionalidad compatible
.\scripts\publish-version.ps1 -Version "2.1.0"
```

---

## 📊 Comparativa de etiquetas generadas

| Versión | Etiqueta Git | Etiquetas de imagen Docker | ¿Actualiza `latest`? | Uso recomendado |
|---------|--------------|----------------------------|----------------------|-----------------|
| `1.0.0` | `v1.0.0` | `1.0.0`, `1.0`, `1`, `latest`, `sha-*` | ✅ Sí | Producción |
| `1.0.1` | `v1.0.1` | `1.0.1`, `1.0`, `1`, `latest`, `sha-*` | ✅ Sí | Hotfix |
| `1.1.0` | `v1.1.0` | `1.1.0`, `1.1`, `1`, `latest`, `sha-*` | ✅ Sí | Nueva funcionalidad |
| `2.0.0-alpha1` | `v2.0.0-alpha1` | `2.0.0-alpha1`, `sha-*` | ❌ No | Desarrollo interno |
| `2.0.0-beta1` | `v2.0.0-beta1` | `2.0.0-beta1`, `sha-*` | ❌ No | Pruebas públicas |
| `2.0.0-rc1` | `v2.0.0-rc1` | `2.0.0-rc1`, `sha-*` | ❌ No | Release candidate |
| `2.0.0` | `v2.0.0` | `2.0.0`, `2.0`, `2`, `latest`, `sha-*` | ✅ Sí | Producción (versión con cambios incompatibles) |

---

## ✅ Buenas prácticas

### ✅ SÍ

- Usa preversiones para probar antes de las versiones mayores.
- Sigue estrictamente el versionado semántico.
- Documenta los cambios incompatibles en `v2.0.0`, `v3.0.0`, etc.
- Haz primero un dry run para verificar la publicación:
  `.\scripts\publish-version.ps1 -Version "1.0.0" -DryRun`
- Haz commit de todos los cambios antes de crear una versión.

### ❌ NO

- ❌ No uses preversiones en producción.
- ❌ No te saltes números de versión (por ejemplo, de `1.0.0` a `1.3.0`).
- ❌ No introduzcas cambios incompatibles en versiones minor o patch.
- ❌ No reutilices números de versión borrando y recreando etiquetas.
- ❌ No publiques versiones sin probarlas adecuadamente.

---

## 🎯 Ejemplos de imágenes Docker

### Producción (siempre estable)

```yaml
# docker-compose.yml
services:
  api:
    image: ghcr.io/evaristocuesta/clovance/clovance-api:latest
    # O una versión concreta:
    # image: ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```

### Pruebas (preversión concreta)

```yaml
services:
  api:
    image: ghcr.io/evaristocuesta/clovance/clovance-api:2.0.0-beta1
```

---

## 🔍 Solución de problemas

### Error: «The tag 'vX.Y.Z' already exists»

```powershell
# Lista las etiquetas existentes
git tag -l

# Si realmente quieres reemplazarla (NO RECOMENDADO):
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# Vuelve a publicarla
.\scripts\publish-version.ps1 -Version "1.0.0"
```

### Ver el workflow de GitHub Actions

```text
https://github.com/evaristocuesta/clovance/actions
```

### Verificar las imágenes publicadas

```bash
# Descargar una versión concreta
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0
```
