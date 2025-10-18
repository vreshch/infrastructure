#!/bin/bash

# Make script exit on any error
set -euo pipefail

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/init-swarm.log
}

log "Starting Docker Swarm initialization..."

# Wait for Docker to be ready
log "Waiting for Docker to be ready..."
timeout 300 bash -c 'until docker info > /dev/null 2>&1; do echo "Waiting for Docker to be ready..."; sleep 5; done'

log "Docker is ready"

# Get the server's main IP address (excluding loopback and docker networks)
SERVER_IP=$(ip -4 addr | grep -v '127\.' | grep -v '172\.17\.' | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+(?=/)' | head -n 1)

if [ -z "$SERVER_IP" ]; then
    log "Error: Could not determine server IP address"
    log "Available network interfaces:"
    ip addr show | grep -E '^[0-9]+:' | tee -a /var/log/init-swarm.log
    log "IP addresses found:"
    ip -4 addr | grep inet | tee -a /var/log/init-swarm.log
    exit 1
fi

log "Server IP detected: $SERVER_IP"

# Check if node is already part of a swarm
if ! docker info | grep -q "Swarm: active"; then
    log "Initializing Docker Swarm with IP: $SERVER_IP"
    if ! docker swarm init --advertise-addr $SERVER_IP; then
        log "Error: Failed to initialize Docker Swarm"
        exit 1
    fi
    log "Docker Swarm initialized successfully"
else
    log "Node is already part of a swarm"
fi

# Create required overlay networks if they don't exist
if ! docker network ls | grep -q "traefik-public"; then
    log "Creating traefik-public network..."
    docker network create --driver=overlay --attachable --opt encrypted=true traefik-public
else
    log "traefik-public network already exists"
fi

if ! docker network ls | grep -q "backend"; then
    log "Creating backend network..."
    docker network create --driver=overlay --attachable --opt encrypted=true backend
else
    log "backend network already exists"
fi

# Add required labels to the node
log "Adding node labels..."
NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
docker node update --label-add manager=true $NODE_ID
docker node update --label-add traefik=true $NODE_ID
docker node update --label-add monitoring=true $NODE_ID

log "Docker Swarm initialization completed successfully"
