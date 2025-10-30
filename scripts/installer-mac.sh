#!/bin/zsh

set -e

echo "[optorMc] Welcome!"

# Check for Docker
if ! command -v docker &> /dev/null; then
  echo "Docker is not installed. Please install Docker Desktop from https://www.docker.com/products/docker-desktop/ and rerun this script."
  exit 1
fi

echo "Docker found. Setting up optorMc..."

# Clone repo step (placeholder)
# echo "Cloning repo..."
# git clone https://github.com/your/repo.git

# Pull required Docker images
cd "$(dirname "$0")/.."
echo "Pulling Docker images..."
docker-compose pull || true

echo "Bringing up containers..."
docker-compose up -d

sleep 3
echo "If all containers are healthy, open http://localhost:3000 in your browser!"
