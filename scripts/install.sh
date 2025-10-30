#!/usr/bin/env bash

# optorMc.com universal installer (macOS, Linux)
set -e

# --- COLOR LOGGING ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${CYAN}[optorMc]${NC} $1"; }
print_success() { echo -e "${GREEN}[✔]${NC} $1"; }
print_error() { echo -e "${RED}[✖]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- OS DETECTION ---
case "$(uname -s)" in
    Darwin*)   OS=mac;;
    Linux*)    OS=linux;;
    *)         print_error "Unsupported OS: $(uname -s)"; exit 1;;
esac

print_info "Installer running on $OS."

# --- XCODE COMMAND LINE TOOLS CHECK (macOS only) ---
if [ "$OS" = "mac" ]; then
  if ! xcode-select -p &>/dev/null; then
    print_warn "Xcode Command Line Tools not found. Installing..."
    xcode-select --install
    print_info "Waiting for Xcode Command Line Tools installation to finish..."
    until xcode-select -p &>/dev/null; do
      sleep 5
    done
    print_success "Xcode Command Line Tools installed!"
  else
    print_success "Xcode Command Line Tools already installed."
  fi
fi

# --- HOMEBREW CHECK & SETUP (macOS only) ---
auto_install_brew_mac() {
  if ! command -v brew &>/dev/null; then
    print_warn "Homebrew is not installed. Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed!"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  else
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  fi
}

install_pkg_mac() {
  pkg=$1
  if ! command -v $pkg &>/dev/null; then
    print_warn "$pkg is not installed. Installing $pkg with Homebrew..."
    if ! brew install $pkg; then
      print_warn "Trying again as sudo..."
      sudo brew install $pkg
    fi
    print_success "$pkg installed!"
  fi
}

# --- DEPENDENCIES: DOCKER + DOCKER COMPOSE ---
if [ "$OS" = "mac" ]; then
  auto_install_brew_mac
  install_pkg_mac docker
  install_pkg_mac docker-compose
fi

if ! command -v docker &> /dev/null; then
  if [ "$OS" = "mac" ]; then
    open "https://www.docker.com/products/docker-desktop"
  fi
  print_error "Docker is not installed and could not be installed automatically. Exiting."
  exit 1
fi

# --- DOCKER DAEMON CHECK ---
if ! docker info >/dev/null 2>&1; then
  if [ "$OS" = "mac" ]; then
    # Try to launch Docker Desktop and wait up to 2 minutes
    MAX_TRIES=24
    COUNT=0
    while ! docker info >/dev/null 2>&1; do
      ((COUNT++))
      open -a "Docker" 2>/dev/null || true
      sleep 5
      if [ $COUNT -ge $MAX_TRIES ]; then
        print_error "Docker Desktop did not start within 2 minutes. Exiting."
        exit 1
      fi
    done
    print_success "Docker Desktop is running."
  else
    print_error "Docker daemon is not running. Please start Docker Engine and rerun this installer."
    exit 1
  fi
fi

# --- DOCKER-COMPOSE DETECTION ---
if docker compose version >/dev/null 2>&1; then
  DC='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
  DC='docker-compose'
else
  if [ "$OS" = "mac" ]; then
    install_pkg_mac docker-compose
    if command -v docker-compose >/dev/null 2>&1; then
      DC='docker-compose'
    else
      print_error "docker-compose not available even after attempting install. Exiting."
      exit 1
    fi
  else
    print_error "docker-compose is not installed and cannot be installed automatically. Exiting."
    exit 1
  fi
fi

print_success "All Docker-related dependencies are present.\n"

# --- DOCKER IMAGE PULL ---
print_info "Pulling Docker images (may take a few minutes on first run)..."
$DC pull || true

# --- START CONTAINERS ---
print_info "Starting optorMc platform..."
$DC up -d

# --- HEALTH CHECK ---
print_info "Checking container health..."
sleep 4

if ! $DC ps | grep -q "Up"; then
  print_error "One or more services are not running. Use '$DC logs' for troubleshooting."
  exit 1
fi
print_success "All services are running!"

# --- ATTEMPT TO OPEN BROWSER ---
if [ "$OS" = "mac" ]; then
  open http://localhost:3000 2>/dev/null || true
else
  xdg-open http://localhost:3000 2>/dev/null || true
fi

print_success "optorMc.com should be available at http://localhost:3000."

# --- FORCE CREATE frontend package.json EVERY TIME ---
FRONTEND_PKG="/Users/jonesy/Desktop/Projects/optorMc.com/frontend/package.json"
cat <<EOL > "$FRONTEND_PKG"
{
  "name": "optormc-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "echo 'No dev server specified.' && exit 1",
    "build": "echo 'No build step.' && exit 0"
  },
  "dependencies": {},
  "devDependencies": {}
}
EOL

# --- REMOVE .dockerignore TO PREVENT FILE EXCLUSION ---
FRONTEND_IGNORE="/Users/jonesy/Desktop/Projects/optorMc.com/frontend/.dockerignore"
if [ -f "$FRONTEND_IGNORE" ]; then rm "$FRONTEND_IGNORE"; fi

# --- GENERATE OTHER DEFAULTS AS BEFORE (use prior code for backend pkg/dockerfiles/db envs) ---
BACKEND_PKG="/Users/jonesy/Desktop/Projects/optorMc.com/backend/package.json"
if [ ! -f "$BACKEND_PKG" ]; then
  cat <<EOL > "$BACKEND_PKG"
{
  "name": "optormc-backend",
  "version": "1.0.0",
  "main": "src/index.js",
  "type": "commonjs",
  "scripts": {
    "start": "node src/index.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOL
fi
FRONTEND_DOCKERFILE="/Users/jonesy/Desktop/Projects/optorMc.com/frontend/Dockerfile"
if [ ! -f "$FRONTEND_DOCKERFILE" ]; then
  cat <<EOL > "$FRONTEND_DOCKERFILE"
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install || true
COPY . .
EXPOSE 3000
CMD ["npm", "run", "dev"]
EOL
fi
BACKEND_DOCKERFILE="/Users/jonesy/Desktop/Projects/optorMc.com/backend/Dockerfile"
if [ ! -f "$BACKEND_DOCKERFILE" ]; then
  cat <<EOL > "$BACKEND_DOCKERFILE"
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5000
CMD ["npm", "start"]
EOL
fi
COMPOSE_FILE="/Users/jonesy/Desktop/Projects/optorMc.com/docker-compose.yml"
ENV_FILE="/Users/jonesy/Desktop/Projects/optorMc.com/.env"
if grep -E 'image:.*(postgres|mysql|mariadb|mongo)' "$COMPOSE_FILE" >/dev/null 2>&1; then
  if [ ! -f "$ENV_FILE" ]; then
    cat <<EOL > "$ENV_FILE"
DB_USER=defaultuser
DB_PASS=defaultpass
DB_NAME=optormc
EOL
  fi
fi

# --- FORCE DOCKER REBUILD WITH NO CACHE TO PICK UP FILES ---
docker compose build --no-cache

# If anything was generated warn at end
NOTICE_GEN=0
[ ! -f "$FRONTEND_PKG" ] && NOTICE_GEN=1
[ ! -f "$BACKEND_PKG" ] && NOTICE_GEN=1
[ ! -f "$FRONTEND_DOCKERFILE" ] && NOTICE_GEN=1
[ ! -f "$BACKEND_DOCKERFILE" ] && NOTICE_GEN=1
if [ -f "$ENV_FILE" ]; then
  NOTICE_GEN=1
fi
if [ $NOTICE_GEN -eq 1 ]; then
  print_warn "[autogen] Some default settings, Dockerfiles or credentials were auto-generated. Review and edit as needed."
fi
