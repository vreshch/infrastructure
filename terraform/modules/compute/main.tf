terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Data source for Ubuntu 22.04 image
data "hcloud_image" "ubuntu" {
  name = "ubuntu-22.04"
}

# Create SSH key resource
resource "hcloud_ssh_key" "server_ssh_key" {
  name       = "${var.server_name}-key-${var.environment}"
  public_key = var.ssh_public_key
}

# Create firewall for the server
resource "hcloud_firewall" "server_firewall" {
  name = "${var.server_name}-firewall"

  # SSH Access
  rule {
    direction  = "in"
    port       = "22"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTP
  rule {
    direction  = "in"
    port       = "80"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  rule {
    direction  = "in"
    port       = "443"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Docker Swarm - Manager API
  rule {
    direction  = "in"
    port       = "2377"
    protocol   = "tcp"
    source_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # Docker Swarm - Node Communication
  rule {
    direction  = "in"
    port       = "7946"
    protocol   = "tcp"
    source_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  rule {
    direction  = "in"
    port       = "7946"
    protocol   = "udp"
    source_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # Docker Swarm - Overlay Network
  rule {
    direction  = "in"
    port       = "4789"
    protocol   = "udp"
    source_ips = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  # Application ports - Frontend (Next.js) and Backend (Express.js)
  rule {
    direction  = "in"
    port       = "3000"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    port       = "4000"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Create the server
resource "hcloud_server" "main_server" {
  name        = var.server_name
  image       = data.hcloud_image.ubuntu.id
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.server_ssh_key.id]

  firewall_ids = [hcloud_firewall.server_firewall.id]

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }

  user_data = <<-EOF
              #!/bin/bash

              # Enable logging and error handling
              set -euo pipefail
              exec > >(tee -a /var/log/user-data.log) 2>&1

              log() {
                  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
              }

              log "Starting server initialization..."

              cat > /root/init-docker.sh <<'DOCKERSCRIPT'
              ${file("${path.module}/scripts/init-docker.sh")}
              DOCKERSCRIPT

              # Make docker installation script executable and run it
              chmod +x /root/init-docker.sh
              log "Running Docker installation..."
              /root/init-docker.sh

              %{if var.enable_docker_swarm}
              # Copy docker swarm initialization script
              cat > /root/init-docker-swarm.sh <<'SWARMSCRIPT'
              ${file("${path.module}/scripts/init-docker-swarm.sh")}
              SWARMSCRIPT

              # Make script executable and run it
              chmod +x /root/init-docker-swarm.sh
              log "Running Docker Swarm initialization..."
              /root/init-docker-swarm.sh
              %{endif}

              # Copy deploy-services script
              cat > /root/deploy-services.sh <<'DEPLOYSCRIPT'
              ${file("${path.module}/scripts/deploy-services.sh")}
              DEPLOYSCRIPT

              # Make deploy-services script executable
              chmod +x /root/deploy-services.sh

              cat > /root/.service-config <<'SERVICECONFIG'
              # Service Configuration Variables
              export ADMIN_PASSWORD_HASH="${var.admin_password_hash}"
              export TRAEFIK_HOST="${var.traefik_host}"
              export SWARMPIT_HOST="${var.swarmpit_host}"
              export DOZZLE_HOST="${var.dozzle_host}"
              export TRAEFIK_ACME_EMAIL="${var.traefik_acme_email}"
              export TRAEFIK_USERNAME="admin"
              SERVICECONFIG

              # Wait for Docker and Swarm to be fully ready
              log "Waiting for Docker services to stabilize..."
              sleep 10

              # Execute the deploy-services script to deploy Traefik automatically
              log "Running automatic Traefik deployment..."
              source /root/.service-config
              /root/deploy-services.sh

              # Create completion marker
              log "Server initialization completed successfully!"
              touch /root/.server-ready

              log "All initialization tasks completed!"
              EOF

  # Ensure server is ready before considering it complete
  lifecycle {
    create_before_destroy = true
  }
}
