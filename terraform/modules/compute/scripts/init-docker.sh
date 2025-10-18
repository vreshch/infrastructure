#!/bin/bash

# Enable exit on error and better debugging
set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/install-docker.log
}

log "Starting Docker installation..."

# Set up the server hostname
if [ ! -z "${USE_HOSTNAME:-}" ]; then
    log "Setting hostname to: $USE_HOSTNAME"
    echo "$USE_HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
fi

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Docker prerequisites
log "Installing Docker prerequisites..."
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common

# Add Docker's official GPG key
log "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker repository
log "Adding Docker repository..."
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

# Install Docker
log "Installing Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
log "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

# Configure Docker daemon
log "Configuring Docker daemon..."
cat > /etc/docker/daemon.json <<'DOCKERCONF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DOCKERCONF

# Restart Docker to apply changes
log "Restarting Docker service..."
systemctl restart docker

# Wait for Docker to be ready
log "Waiting for Docker to be ready..."
timeout 60 bash -c 'until docker info >/dev/null 2>&1; do echo "Waiting for Docker..."; sleep 2; done'

log "Docker installation completed successfully!"
