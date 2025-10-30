# optorMc.com installer for Windows (PowerShell)
$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[optorMc] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[✔] $msg" -ForegroundColor Green }
function Write-ErrorMsg($msg) { Write-Host "[✖] $msg" -ForegroundColor Red }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }

Write-Info "Detecting environment..."

# Dependency checks
if (-not (Get-Command 'git' -ErrorAction SilentlyContinue)) {
  Write-ErrorMsg "git is required. Please install from https://git-scm.com/downloads"
  exit 1
}
if (-not (Get-Command 'docker' -ErrorAction SilentlyContinue)) {
  Write-ErrorMsg "Docker Desktop is required. Please install from https://www.docker.com/products/docker-desktop/"
  exit 1
}

# Test if Docker is running
try {
  docker info | Out-Null
} catch {
  Write-ErrorMsg "Docker daemon is not running. Please start Docker Desktop."
  exit 1
}

# docker-compose (Docker Desktop now supplies Compose as 'docker compose')
$compose = 'docker compose'
try {
  docker compose version | Out-Null
} catch {
  if (Get-Command 'docker-compose' -ErrorAction SilentlyContinue) {
    $compose = 'docker-compose'
  } else {
    Write-ErrorMsg "docker-compose is required (usually provided by Docker Desktop)."
    exit 1
  }
}

Write-Success "All dependencies are present."

# Check for docker-compose.yml
if (-not (Test-Path "docker-compose.yml")) {
  Write-Warn "Not in optorMc.com project directory."
  $answer = Read-Host "Clone latest from GitHub? (y/n)"
  if ($answer -eq 'y' -or $answer -eq 'Y') {
    git clone https://github.com/USERNAME/optorMc.com.git
    Set-Location optorMc.com
  } else {
    Write-ErrorMsg "Must run in project directory."; exit 1
  }
}

Write-Info "Pulling Docker images..."
Invoke-Expression "$compose pull"

Write-Info "Starting platform..."
Invoke-Expression "$compose up -d"
Start-Sleep -Seconds 4

Write-Info "Checking container status..."
$ps = $(Invoke-Expression "$compose ps")
if (-Not ($ps -match "Up")) {
  Write-ErrorMsg "One or more services not running. Use '$compose logs'."
  exit 1
}
Write-Success "All services are running!"

try {
  Start-Process http://localhost:3000
} catch {
  Write-Warn "Couldn't open browser. Visit http://localhost:3000 manually."
}

Write-Success "optorMc.com should be available at http://localhost:3000."
