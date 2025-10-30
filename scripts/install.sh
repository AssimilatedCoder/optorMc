#!/usr/bin/env bash

set -euo pipefail

echo "[optorMc] Installer starting..."

OS="$(uname -s)"

if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker Desktop: https://www.docker.com/products/docker-desktop/"
  exit 1
fi

# Ensure Docker Desktop is running on macOS
if [ "$OS" = "Darwin" ]; then
  if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker Desktop..."
    open -a Docker || true
    for i in {1..24}; do
      if docker info >/dev/null 2>&1; then
        break
      fi
      sleep 5
    done
    if ! docker info >/dev/null 2>&1; then
      echo "Docker Desktop did not start in time. Please start it manually and retry."
      exit 1
    fi
  fi
fi

if docker compose version >/dev/null 2>&1; then
  DC='docker compose'
elif command -v docker-compose >/dev/null 2>&1; then
  DC='docker-compose'
else
  echo "docker compose is not available. Please update Docker Desktop."
  exit 1
fi

MODE="dev"
BUILD_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --prod)
      MODE="prod";;
    --build)
      BUILD_FLAG="--build";;
  esac
done

if [ "$MODE" = "prod" ]; then
  echo "Bringing up production stack..."
  $DC -f docker-compose.yml -f docker-compose.prod.yml up -d $BUILD_FLAG
else
  echo "Bringing up development stack..."
  $DC up -d $BUILD_FLAG
fi

echo "Waiting for containers to initialize..."
sleep 3

if ! $DC ps | grep -q "Up"; then
  echo "Some services did not start. Use '$DC logs' to troubleshoot."
  exit 1
fi

echo "Opening http://localhost ..."
if [ "$OS" = "Darwin" ]; then
  open http://localhost || true
else
  xdg-open http://localhost 2>/dev/null || true
fi

echo "[optorMc] Done. Access the app at http://localhost"
