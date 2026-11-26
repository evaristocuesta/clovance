---
title: Publishing Docker Images
description: How Clovance publishes Docker images to GitHub Container Registry (GHCR) with GitHub Actions.
lang: en
translation: /DOCKER_PUBLISH.es.html
---

# Publishing Docker Images with GitHub Actions

This document explains how automatic publishing of Docker images to GitHub Container Registry (GHCR) works.

## 🚀 Publishing Process

### Automatic with Script (Recommended)

Use the included PowerShell script to safely create and publish new versions:

```powershell
# From the repository root

# Production release
.\scripts\publish-version.ps1 -Version "1.0.0"

# Pre-release (beta, rc, alpha)
.\scripts\publish-version.ps1 -Version "1.0.0-beta1"
.\scripts\publish-version.ps1 -Version "2.0.0-rc2"
.\scripts\publish-version.ps1 -Version "1.0.0-alpha1"

# Preview what would happen without executing it (dry run)
.\scripts\publish-version.ps1 -Version "1.0.0" -DryRun
```

The script automatically verifies:

- ✅ Correct version format (`X.Y.Z` or `X.Y.Z-prerelease`)
- ✅ No uncommitted changes
- ✅ Your local branch is up to date with the remote
- ✅ The tag does not already exist

### Manual

You can also create tags manually:

```bash
# Create a production release tag
git tag v1.0.0

# Create a pre-release tag
git tag v1.0.0-beta1

# Push the tag to GitHub
git push origin v1.0.0
# or
git push origin v1.0.0-beta1
```

### What Happens Automatically

This triggers the GitHub Actions workflow, which will:

1. Build the Docker images for the API and Frontend.
2. Tag them with multiple Docker image tags (note: image tags never use the `v` prefix):
   - `1.0.0` (full version)
   - `1.0` (major.minor)
   - `1` (major)
   - `latest` (stable releases only)
   - `sha-<sha>` (short commit SHA)
3. Publish them to `ghcr.io/evaristocuesta/clovance/`.
4. Generate a provenance attestation.

The Git tag (`v1.0.0`) is the only Git tag created; the tags above belong to the Docker images.

### Published Images

- **API**: `ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0`
- **Frontend**: `ghcr.io/evaristocuesta/clovance/clovance-frontend:1.0.0`

## 📦 Tag Structure

The workflow automatically generates multiple tags for each version.

### Production Releases

```
Git tag v1.2.3 → Docker image tags generated:
  - 1.2.3           (full version)
  - 1.2             (major.minor)
  - 1               (major)
  - latest          (stable releases only)
  - sha-abc1234     (short commit SHA)
```

### Pre-releases (beta, rc, alpha)

```
Git tag v1.2.3-beta1 → Docker image tags generated:
  - 1.2.3-beta1     (full version)
  - sha-abc1234     (short commit SHA)

⚠️ Pre-releases DO NOT update:
  - major.minor (1.2)
  - major (1)
  - latest
```

This ensures that preview releases do not overwrite stable production releases.

## 🔧 Local Development with Aspire

### Local Development

To run the application locally with Aspire:

```bash
cd api/aspire/Clovance.AppHost
dotnet run
```

This uses `appsettings.Development.json` and **does not** attempt to publish containers.

### Generate Deployment Manifests

Aspire can generate deployment artifacts from the application model (Docker Compose, Kubernetes, etc.) that reference the images published to GHCR. Starting with Aspire 17, publishing goes through the Aspire CLI; `dotnet run --operation publish` is rejected:

```bash
# Generate deployment artifacts (writes to ./aspire-output)
cd api/aspire/Clovance.AppHost
aspire publish -e Production

# Or choose a different output directory
aspire publish -e Production -o ./manifests
```

This generates deployment files ready to use with the images published in GHCR.

## 🐳 Test Local Builds

### API Service

```bash
# From the repository root
docker build -t clovance-api:local -f api/src/Clovance.ApiService/Dockerfile .
docker run -p 8080:8080 clovance-api:local
```

### Frontend

```bash
# From the frontend directory
cd frontend
docker build -t clovance-frontend:local .
docker run -p 8000:8000 clovance-frontend:local
```

## 🔐 GHCR Permissions

Images are published as public by default. To change their visibility:

1. Go to https://github.com/evaristocuesta?tab=packages
2. Find the package (`clovance-api` or `clovance-frontend`)
3. Open **Package settings**
4. Change the visibility to **Public** or **Private**

## 📋 Workflow Requirements

The workflow requires the following permissions (already configured):

- `contents: read` - To clone the repository
- `packages: write` - To publish to GHCR

It automatically uses {% raw %}`${{ secrets.GITHUB_TOKEN }}`{% endraw %}, which GitHub generates for every workflow run.

## 🔄 Semantic Versioning

It is recommended to follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (`v1.0.0` → `v2.0.0`): Breaking API changes
- **MINOR** (`v1.0.0` → `v1.1.0`): New backward-compatible functionality
- **PATCH** (`v1.0.0` → `v1.0.1`): Bug fixes
- **PRE-RELEASE** (`v1.0.0-beta1`): Preview versions before the official release

### Versioning Examples

```bash
# Development and testing
git tag v1.0.0-alpha && git push origin v1.0.0-alpha    # Very early version
git tag v1.0.0-beta1 && git push origin v1.0.0-beta1  # First beta
git tag v1.0.0-beta2 && git push origin v1.0.0-beta2  # Second beta
git tag v1.0.0-rc1 && git push origin v1.0.0-rc1      # Release candidate

# Production
git tag v1.0.0 && git push origin v1.0.0  # Initial release
git tag v1.0.1 && git push origin v1.0.1  # Bug fix
git tag v1.1.0 && git push origin v1.1.0  # New feature
git tag v2.0.0 && git push origin v2.0.0  # Breaking change
```

## 🚨 Troubleshooting

### When Should I Use Pre-releases?

Use pre-releases for:

- ✅ Testing new features before release
- ✅ Public beta versions for early adopters
- ✅ Release candidates before a final release
- ✅ Alpha versions during early development

**Do NOT use pre-releases for:**

- ❌ Stable production releases
- ❌ Urgent hotfixes (use production releases instead)

### Using a Pre-release in Production

If you need to use a specific pre-release:

```yaml
# docker-compose.yml
services:
  api:
    image: ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta1
```

```bash
# Docker pull
docker pull ghcr.io/evaristocuesta/clovance/clovance-api:1.0.0-beta1
```

### The Workflow Fails with "permission denied"

Verify that the repository has **Read and write permissions** enabled for GitHub Actions:

1. **Settings → Actions → General**
2. **Workflow permissions → Read and write permissions**

### Images Do Not Appear in GHCR

It may take a few minutes for the images to appear. Check:

1. The workflow completed successfully: https://github.com/evaristocuesta/clovance/actions
2. The packages are available at: https://github.com/evaristocuesta?tab=packages

### I Want to Change the Registry

Edit `.github/workflows/publish-images.yml` and change:

```yaml
env:
  REGISTRY: ghcr.io  # Change to docker.io, quay.io, etc.
```

Also update `appsettings.Production.json`:

```json
{
  "Parameters": {
    "container-registry": "docker.io/your-username/clovance"
  }
}
```

## 📚 References

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [.NET Aspire Deployment](https://learn.microsoft.com/en-us/dotnet/aspire/deployment/overview)
- [Docker Build Push Action](https://github.com/marketplace/actions/build-and-push-docker-images)