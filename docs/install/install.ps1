<#
.SYNOPSIS
  Clovance installer for Windows.
.DESCRIPTION
  Usage:
    .\install.ps1            (install)
    .\install.ps1 install
    .\install.ps1 uninstall
    .\install.ps1 update
#>
param(
  [ValidateSet("install","uninstall","update")]
  [string]$Command = "install"
)

$ErrorActionPreference = "Stop"

$DefaultInstallDir  = Join-Path $env:USERPROFILE "clovance"
$DefaultVersion     = "latest"
$DefaultFrontendPort = "7000"
$DefaultApiPort     = "8080"
$DefaultBind        = "0.0.0.0"
$DefaultDashBind    = "127.0.0.1"

# True when the script runs as a file (.\install.ps1). False when it was piped
# into Invoke-Expression (irm ... | iex), where "exit" would close the console.
$RunningAsFile = [bool]$PSScriptRoot

function Log   { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Warn  { param($m) Write-Host "!!  $m" -ForegroundColor Yellow }
function Err   { param($m) Write-Host "xx  $m" -ForegroundColor Red }

function Read-Value {
  param([string]$Message, [string]$Default)
  if ([Environment]::UserInteractive) {
    $val = Read-Host "$Message [$Default]"
    if ([string]::IsNullOrWhiteSpace($val)) { $val = $Default }
  } else { $val = $Default }
  return ([string]$val).Trim()
}

function Test-Yes {
  param([string]$Value)
  return ($Value -match '^(?i)y(es)?$')
}

function Read-Secret {
  param([string]$Message, [string]$Existing)
  $label = if ($Existing) { "$Message (empty = keep current)" } else { $Message }
  if (-not [Environment]::UserInteractive) { return $Existing }
  $sec = Read-Host $label -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
  try { $val = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  if ([string]::IsNullOrWhiteSpace($val)) { return $Existing }
  return $val
}

function GenPassword {
  $bytes = New-Object byte[] 18
  $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
  $rng.GetBytes($bytes)
  $rng.Dispose()
  return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','_').Replace('/','-')
}

# Returns $Fallback when $Value is empty. Keeps the prompt defaults readable.
function Get-OrDefault {
  param($Value, $Fallback)
  if ([string]::IsNullOrWhiteSpace([string]$Value)) { return $Fallback }
  return $Value
}

function Require($cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "Missing required command: $cmd" }
}

# Runs docker and fails loudly on a non-zero exit code. Native commands do NOT
# raise exceptions, so without this check a broken daemon looks like success.
function Invoke-Docker {
  # No param() block on purpose: "docker compose up -d" would otherwise bind
  # "-d" to a parameter of this function instead of forwarding it.
  & docker @args
  if ($LASTEXITCODE -ne 0) {
    throw "docker $($args -join ' ') failed (exit code $LASTEXITCODE)."
  }
}

function Test-DockerDaemon {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
  & docker info *> $null
  return ($LASTEXITCODE -eq 0)
}

function Check-Docker {
  Require docker
  if (-not (Test-DockerDaemon)) {
    throw "Docker daemon is not running. Start Docker Desktop and retry."
  }
  & docker compose version *> $null
  if ($LASTEXITCODE -ne 0) { throw "Docker Compose plugin (v2) is required." }
}

function Get-EnvValue {
  param([string]$Path, [string]$Key)
  if (-not (Test-Path $Path)) { return $null }
  foreach ($line in Get-Content $Path) {
    if ($line -match "^\s*$([regex]::Escape($Key))=(.*)$") { return $matches[1] }
  }
  return $null
}

function Test-HasExistingData {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $false }
  return [bool](Get-ChildItem $Path -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Assert-ComposeRunning {
  param([string]$InstallDir, [int]$Minimum = 2, [int]$TimeoutSeconds = 60)
  if ($env:CLOVANCE_VERIFY_TIMEOUT) { $TimeoutSeconds = [int]$env:CLOVANCE_VERIFY_TIMEOUT }
  # A container that crashes right after "up -d" shows up as "restarting", not
  # running, so wait a bit for the stack to settle before declaring success.
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $running = 0
  $broken = 0
  do {
    $states = @(& docker compose ps --format '{{.State}}' 2>$null)
    $running = @($states | Where-Object { $_ -eq 'running' }).Count
    $broken = @($states | Where-Object { $_ -and $_ -ne 'running' }).Count
    if ($running -ge $Minimum -and $broken -eq 0) { return }
    Start-Sleep -Seconds 1
  } while ((Get-Date) -lt $deadline)
  throw "Clovance did not start correctly ($running container(s) running, $broken not running). Check 'docker compose ps' and 'docker compose logs' in $InstallDir."
}

function ToPosixPath($p) {
  # Convert Windows path to Docker-friendly POSIX path (C:\foo -> /c/foo)
  $p = $p -replace '\\','/'
  if ($p -match '^([A-Za-z]):/(.*)$') {
    $drive = $matches[1].ToLower()
    $rest  = $matches[2]
    return "/$drive/$rest"
  }
  return $p
}

$ComposeContent = @'
services:
  env-dashboard:
    image: "mcr.microsoft.com/dotnet/nightly/aspire-dashboard:13.6"
    ports:
      - "${CLOVANCE_DASHBOARD_BIND_ADDRESS:-0.0.0.0}::18888"
    expose:
      - "18889"
      - "18890"
    networks:
      - "aspire"
    restart: "always"
  clovance-postgres:
    image: "docker.io/library/postgres:18.3"
    environment:
      POSTGRES_HOST_AUTH_METHOD: "scram-sha-256"
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256 --auth-local=scram-sha-256"
      POSTGRES_USER: "${POSTGRES_USERNAME}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "clovance-database"
    expose:
      - "5432"
    volumes:
      - type: "bind"
        target: "/var/lib/postgresql"
        source: "${VOLUME_SOURCE_PATH}/postgres"
        read_only: false
    networks:
      - "aspire"
    restart: "unless-stopped"
  clovance-apiservice:
    image: "${CLOVANCE_APISERVICE_IMAGE}"
    environment:
      OTEL_DOTNET_EXPERIMENTAL_OTLP_RETRY: "in_memory"
      ASPNETCORE_FORWARDEDHEADERS_ENABLED: "true"
      HTTP_PORTS: "${CLOVANCE_APISERVICE_PORT}"
      ConnectionStrings__clovance-database: "Host=clovance-postgres;Port=5432;Username=${POSTGRES_USERNAME};Password=${POSTGRES_PASSWORD};Database=clovance-database"
      CLOVANCE_DATABASE_HOST: "clovance-postgres"
      CLOVANCE_DATABASE_PORT: "5432"
      CLOVANCE_DATABASE_USERNAME: "${POSTGRES_USERNAME}"
      CLOVANCE_DATABASE_PASSWORD: "${POSTGRES_PASSWORD}"
      CLOVANCE_DATABASE_URI: "postgresql://${POSTGRES_USERNAME}:${POSTGRES_PASSWORD}@clovance-postgres:5432/clovance-database"
      CLOVANCE_DATABASE_JDBCCONNECTIONSTRING: "jdbc:postgresql://clovance-postgres:5432/clovance-database"
      CLOVANCE_DATABASE_DATABASENAME: "clovance-database"
      ASPNETCORE_ENVIRONMENT: "Production"
      Jwt__KeyFilePath: "/home/app/jwt.key"
      Smtp__Host: "${SMTP_HOST}"
      Smtp__Port: "${SMTP_PORT}"
      Smtp__Username: "${SMTP_USERNAME}"
      Smtp__Password: "${SMTP_PASSWORD}"
      Smtp__FromAddress: "${SMTP_FROM_ADDRESS}"
      Smtp__FromName: "${SMTP_FROM_NAME}"
      Frontend__BaseUrl: "${FRONTEND_BASE_URL}"
      OTEL_EXPORTER_OTLP_ENDPOINT: "http://env-dashboard:18889"
      OTEL_EXPORTER_OTLP_PROTOCOL: "grpc"
      OTEL_SERVICE_NAME: "clovance-apiservice"
    expose:
      - "${CLOVANCE_APISERVICE_PORT}"
    volumes:
      - type: "bind"
        target: "/home/app"
        source: "${VOLUME_SOURCE_PATH}/jwt"
        read_only: false
    depends_on:
      clovance-postgres:
        condition: "service_started"
    networks:
      - "aspire"
    restart: "unless-stopped"
  clovance-frontend:
    image: "${CLOVANCE_FRONTEND_IMAGE}"
    command:
      - "nginx"
      - "-g"
      - "daemon off;"
    entrypoint:
      - "/docker-entrypoint.sh"
    environment:
      NODE_ENV: "production"
      CLOVANCE_APISERVICE_HTTP: "http://clovance-apiservice:${CLOVANCE_APISERVICE_PORT}"
      services__clovance-apiservice__http__0: "http://clovance-apiservice:${CLOVANCE_APISERVICE_PORT}"
      CLOVANCE_APISERVICE_HTTPS: "https://clovance-apiservice:${CLOVANCE_APISERVICE_PORT}"
      PORT: "7000"
      OTEL_EXPORTER_OTLP_ENDPOINT: "http://env-dashboard:18889"
      OTEL_EXPORTER_OTLP_PROTOCOL: "grpc"
      OTEL_SERVICE_NAME: "clovance-frontend"
    ports:
      - "${CLOVANCE_BIND_ADDRESS:-0.0.0.0}:7000:7000"
    depends_on:
      clovance-apiservice:
        condition: "service_started"
    networks:
      - "aspire"
    restart: "unless-stopped"
networks:
  aspire:
    driver: "bridge"
'@

function Do-Install {
  Check-Docker
  $installDir = Read-Value "Install directory" $DefaultInstallDir

  # Reuse the current configuration as prompt defaults so re-running the
  # installer does not silently change the database password or lose settings.
  $envPath = Join-Path $installDir ".env"
  $existingVersion = Get-EnvValue $envPath "CLOVANCE_APISERVICE_IMAGE"
  if ($existingVersion -match ':([^:]+)$') { $existingVersion = $matches[1] } else { $existingVersion = $null }
  $existingApiPort = Get-EnvValue $envPath "CLOVANCE_APISERVICE_PORT"
  $existingBind    = Get-EnvValue $envPath "CLOVANCE_BIND_ADDRESS"
  $existingDash    = Get-EnvValue $envPath "CLOVANCE_DASHBOARD_BIND_ADDRESS"
  $existingPgUser  = Get-EnvValue $envPath "POSTGRES_USERNAME"
  $existingPgPass  = Get-EnvValue $envPath "POSTGRES_PASSWORD"
  $existingSmtpHost = Get-EnvValue $envPath "SMTP_HOST"
  $existingSmtpPort = Get-EnvValue $envPath "SMTP_PORT"
  $existingSmtpUser = Get-EnvValue $envPath "SMTP_USERNAME"
  $existingSmtpPass = Get-EnvValue $envPath "SMTP_PASSWORD"
  $existingSmtpFrom = Get-EnvValue $envPath "SMTP_FROM_ADDRESS"
  $existingSmtpName = Get-EnvValue $envPath "SMTP_FROM_NAME"
  $existingFeUrl   = Get-EnvValue $envPath "FRONTEND_BASE_URL"

  $volumePath = Join-Path $installDir "data"
  if (Test-HasExistingData (Join-Path $volumePath "postgres")) {
    Warn "Existing database found in $(Join-Path $volumePath 'postgres')."
    Warn "Keeping the current PostgreSQL password so the API can still connect."
    Warn "To change it, change it inside PostgreSQL first (POSTGRES_PASSWORD is only used when the database is created)."
  }

  $version    = Read-Value "Image version tag (e.g. latest, 1.0.0)" (Get-OrDefault $existingVersion $DefaultVersion)
  $fePort     = Read-Value "Frontend host port" $DefaultFrontendPort
  $apiPort    = Read-Value "API container port" (Get-OrDefault $existingApiPort $DefaultApiPort)
  $bind       = Read-Value "Bind address for frontend" (Get-OrDefault $existingBind $DefaultBind)
  $dashBind   = Read-Value "Bind address for Aspire dashboard" (Get-OrDefault $existingDash $DefaultDashBind)
  $pgUser     = Read-Value "PostgreSQL username" (Get-OrDefault $existingPgUser "clovance")
  $pgPass     = Read-Secret "PostgreSQL password" $existingPgPass
  if ([string]::IsNullOrWhiteSpace($pgPass)) { $pgPass = GenPassword; Log "Generated PostgreSQL password." }
  $smtpHost   = Read-Value "SMTP host" (Get-OrDefault $existingSmtpHost "smtp.example.com")
  $smtpPort   = Read-Value "SMTP port" (Get-OrDefault $existingSmtpPort "587")
  $smtpUser   = Read-Value "SMTP username" (Get-OrDefault $existingSmtpUser "your_smtp_username")
  $smtpPass   = Read-Secret "SMTP password" $existingSmtpPass
  $smtpFrom   = Read-Value "SMTP from address" (Get-OrDefault $existingSmtpFrom "your_smtp_from_address@example.com")
  $smtpName   = Read-Value "SMTP from name" (Get-OrDefault $existingSmtpName "Clovance")
  $feUrl      = Read-Value "Frontend base URL" (Get-OrDefault $existingFeUrl "http://localhost:$fePort")

  New-Item -ItemType Directory -Force -Path $installDir | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $volumePath "postgres") | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $volumePath "jwt") | Out-Null

  $volumePosix = ToPosixPath $volumePath
  $apiImage = "ghcr.io/evaristocuesta/clovance/clovance-api:$version"
  $feImage  = "ghcr.io/evaristocuesta/clovance/clovance-frontend:$version"

  $envContent = @"
CLOVANCE_APISERVICE_IMAGE=$apiImage
CLOVANCE_APISERVICE_PORT=$apiPort
CLOVANCE_FRONTEND_IMAGE=$feImage
FRONTEND_BASE_URL=$feUrl
POSTGRES_PASSWORD=$pgPass
POSTGRES_USERNAME=$pgUser
SMTP_FROM_ADDRESS=$smtpFrom
SMTP_FROM_NAME=$smtpName
SMTP_HOST=$smtpHost
SMTP_PASSWORD=$smtpPass
SMTP_PORT=$smtpPort
SMTP_USERNAME=$smtpUser
VOLUME_SOURCE_PATH=$volumePosix
CLOVANCE_BIND_ADDRESS=$bind
CLOVANCE_DASHBOARD_BIND_ADDRESS=$dashBind
"@
  Set-Content -Path $envPath -Value $envContent -NoNewline
  Set-Content -Path (Join-Path $installDir "docker-compose.yml") -Value $ComposeContent -NoNewline

  Log "Configuration written to $installDir"

  Push-Location $installDir
  try {
    Log "Pulling images..."
    Invoke-Docker compose pull
    Log "Starting Clovance..."
    Invoke-Docker compose up -d
    Log "Verifying containers..."
    Assert-ComposeRunning -InstallDir $installDir
  } finally {
    Pop-Location
  }

  Write-Host ""
  Log "Clovance is running!"
  Write-Host "   Frontend:  http://localhost:$fePort"
  Write-Host "   Data dir:  $volumePath"
  Write-Host ""
  Write-Host "   Aspire dashboard token:"
  Write-Host "     docker logs (docker compose ps -q env-dashboard) 2>&1 | Select-String token"
  Write-Host ""
  Write-Host "   Stop:    cd $installDir; docker compose down"
  Write-Host "   Update:  .\install.ps1 update"
}

function Do-Uninstall {
  Check-Docker
  $installDir = Read-Value "Install directory" $DefaultInstallDir
  $compose = Join-Path $installDir "docker-compose.yml"
  if (-not (Test-Path $compose)) {
    throw "No docker-compose.yml found in $installDir. Nothing to stop there; delete the folder manually if you already removed the config."
  }
  Push-Location $installDir
  try {
    Log "Stopping containers..."
    Invoke-Docker compose down
  } finally { Pop-Location }
  $dataDir = Join-Path $installDir "data"
  $rmvol = Read-Value "Remove data volumes (postgres + jwt)? (y/N)" "N"
  if (Test-Yes $rmvol) {
    Remove-Item -Recurse -Force $dataDir -ErrorAction SilentlyContinue
    if (Test-Path $dataDir) { Warn "Could not remove $dataDir. Close anything using it and delete it manually." }
    else { Log "Data removed." }
  }
  $rmcfg = Read-Value "Remove generated config files (.env, docker-compose.yml)? (y/N)" "N"
  if (Test-Yes $rmcfg) {
    Remove-Item -Force (Join-Path $installDir ".env") -ErrorAction SilentlyContinue
    Remove-Item -Force $compose -ErrorAction SilentlyContinue
    Log "Config removed."
  }
  Log "Uninstall complete."
  Write-Host "   Docker images are kept. To delete them:"
  Write-Host "     docker image rm ghcr.io/evaristocuesta/clovance/clovance-api:latest ghcr.io/evaristocuesta/clovance/clovance-frontend:latest"
}

function Do-Update {
  Check-Docker
  $installDir = Read-Value "Install directory" $DefaultInstallDir
  $envPath = Join-Path $installDir ".env"
  if (-not (Test-Path $envPath)) { throw "No .env found in $installDir." }
  $version = Read-Value "New image version tag" $DefaultVersion
  Copy-Item $envPath "$envPath.bak" -Force
  $lines = Get-Content $envPath
  $lines = $lines | ForEach-Object {
    if ($_ -match '^CLOVANCE_APISERVICE_IMAGE=') { "CLOVANCE_APISERVICE_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-api:$version" }
    elseif ($_ -match '^CLOVANCE_FRONTEND_IMAGE=') { "CLOVANCE_FRONTEND_IMAGE=ghcr.io/evaristocuesta/clovance/clovance-frontend:$version" }
    else { $_ }
  }
  Set-Content -Path $envPath -Value ($lines -join "`r`n") -NoNewline
  Push-Location $installDir
  try {
    Log "Pulling new images..."
    Invoke-Docker compose pull
    Log "Recreating containers..."
    Invoke-Docker compose up -d
    Log "Verifying containers..."
    Assert-ComposeRunning -InstallDir $installDir
  } catch {
    throw "$($_.Exception.Message) The previous configuration was saved to $envPath.bak."
  } finally {
    Pop-Location
  }
  Log "Update complete."
}

try {
  switch ($Command) {
    "install"   { Do-Install }
    "uninstall" { Do-Uninstall }
    "update"    { Do-Update }
  }
} catch {
  Err $_.Exception.Message
  if ($RunningAsFile) { exit 1 }
}
