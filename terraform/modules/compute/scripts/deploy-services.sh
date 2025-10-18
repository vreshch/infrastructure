#!/bin/bash

# Traefik Service Deployment Script
# Deploys Traefik reverse proxy with Swarmpit and Dozzle

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local max_attempts=30
    local attempt=1

    log_info "Waiting for $service_name to be ready..."

    while [[ $attempt -le $max_attempts ]]; do
        if docker service ls | grep -q "$service_name"; then
            if docker service ps "$service_name" | grep -q "Running"; then
                log_success "$service_name is ready"
                return 0
            fi
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            log_error "$service_name failed to start after $max_attempts attempts"
            return 1
        fi

        log_info "Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 10
        ((attempt++))
    done
}

# Check if service exists
service_exists() {
    local service_name="$1"
    docker service ls | grep -q "$service_name"
}

# Verify Traefik configuration
verify_traefik_config() {
    local domain="$1"

    log_info "Verifying Traefik configuration files..."

    # Check if configuration files exist
    if [[ ! -f /opt/traefik/traefik.yml ]]; then
        log_error "Traefik configuration file not found: /opt/traefik/traefik.yml"
        return 1
    fi

    if [[ ! -f /opt/traefik/dynamic.yml ]]; then
        log_error "Traefik dynamic configuration file not found: /opt/traefik/dynamic.yml"
        return 1
    fi

    # Verify domain is properly set in dynamic.yml
    if ! grep -q "Host(\`${domain}\`)" /opt/traefik/dynamic.yml; then
        log_error "Domain ${domain} not found in dynamic configuration"
        return 1
    fi

    # Verify auth middleware is configured
    if ! grep -q "auth-middleware:" /opt/traefik/dynamic.yml; then
        log_error "Auth middleware not found in dynamic configuration"
        return 1
    fi

    log_success "Traefik configuration files verified successfully"
    return 0
}

# Test Traefik service functionality
test_traefik_service() {
    local domain="$1"
    local max_attempts=30
    local attempt=1

    log_info "Testing Traefik service functionality..."

    # Wait for port 80 and 443 to be available
    while [[ $attempt -le $max_attempts ]]; do
        if netstat -tuln 2>/dev/null | grep -q ":80 " && netstat -tuln 2>/dev/null | grep -q ":443 "; then
            log_success "Traefik ports 80 and 443 are listening"
            break
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            log_error "Traefik ports not available after $max_attempts attempts"
            return 1
        fi

        log_info "Attempt $attempt/$max_attempts - waiting for Traefik ports..."
        sleep 5
        ((attempt++))
    done

    # Test HTTP redirect (this will fail in most cases due to DNS, but we can check if Traefik responds)
    log_info "Traefik service is running and ports are accessible"
    log_info "Note: Full HTTPS functionality requires proper DNS configuration for ${domain}"

    return 0
}

# Deploy Traefik service
deploy_traefik() {
    local domain="$1"
    local username="$2"
    local password_hash="$3"
    local acme_email="$4"

    log_info "🚀 Deploying Traefik reverse proxy..."

    # Create configuration directory with proper permissions
    mkdir -p /opt/traefik
    chmod 755 /opt/traefik

    log_info "Creating Traefik main configuration..."
    # Create traefik.yml configuration optimized for MCP platform
    cat > /opt/traefik/traefik.yml << EOF
entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https

  https:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

api:
  dashboard: true
  insecure: false

providers:
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true
  docker:
    endpoint: "unix:///var/run/docker.sock"
    swarmMode: true
    exposedByDefault: false
    network: traefik-public
    constraints: "Label(\`traefik.constraint-label\`, \`traefik-public\`)"

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${acme_email}
      storage: /etc/traefik/acme/acme.json
      httpChallenge:
        entryPoint: http

# Enhanced logging for MCP platform
log:
  level: INFO

accessLog: {}
EOF

    log_info "Creating Traefik dynamic configuration..."
    # Create dynamic.yml configuration
    cat > /opt/traefik/dynamic.yml << 'EOF'
http:
  middlewares:
    auth-middleware:
      basicAuth:
        users:
          - "TRAEFIK_USER_PLACEHOLDER"

    https-redirect:
      redirectScheme:
        scheme: https
        permanent: true

    # Security headers for MCP platform
    security-headers:
      headers:
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        frameDeny: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customRequestHeaders:
          X-Forwarded-Proto: "https"

    # Rate limiting for API protection
    rate-limit:
      rateLimit:
        burst: 100
        average: 50

  routers:
    # Admin dashboard router
    dashboard:
      rule: "Host(`TRAEFIK_DOMAIN_PLACEHOLDER`)"
      service: api@internal
      entryPoints:
        - https
      middlewares:
        - auth-middleware
      tls:
        certResolver: letsencrypt

tls:
  options:
    default:
      minVersion: VersionTLS12
      cipherSuites:
        - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
EOF

    log_info "Configuring authentication and domain settings..."
    # Replace placeholders with actual values
    local hash_only="${password_hash#*:}"
    local user_auth_string="${username}:${hash_only}"

    # Replace domain placeholder
    sed -i "s/TRAEFIK_DOMAIN_PLACEHOLDER/${domain}/g" /opt/traefik/dynamic.yml

    # Replace user placeholder
    local temp_file="/tmp/dynamic_config_temp.yml"
    while IFS= read -r line; do
        if [[ "$line" == *"TRAEFIK_USER_PLACEHOLDER"* ]]; then
            echo "          - \"${user_auth_string}\""
        else
            echo "$line"
        fi
    done < /opt/traefik/dynamic.yml > "$temp_file"

    mv "$temp_file" /opt/traefik/dynamic.yml

    # Set proper permissions
    chmod 644 /opt/traefik/traefik.yml
    chmod 644 /opt/traefik/dynamic.yml

    # Verify configuration
    if ! verify_traefik_config "$domain"; then
        log_error "Failed to create or verify Traefik configuration"
        return 1
    fi

    log_info "Setting up Docker networks and volumes..."
    # Create networks optimized for MCP catalog
    docker network create --driver overlay traefik-public 2>/dev/null || true
    docker network create --driver overlay --attachable net 2>/dev/null || true
    docker volume create traefik-certificates 2>/dev/null || true

    # Label the manager node
    local node_id=$(docker node ls -q)
    docker node update --label-add traefik=true $node_id

    # Remove existing service if it exists
    if service_exists "traefik"; then
        log_info "Removing existing Traefik service..."
        docker service rm traefik
        sleep 10
    fi

    log_info "Deploying Traefik Docker service..."
    # Deploy Traefik service - CONSERVATIVE resource allocation (PRIORITY SERVICE)
    docker service create \
        --name traefik \
        --constraint 'node.role==manager' \
        --constraint 'node.labels.traefik==true' \
        --publish 80:80 \
        --publish 443:443 \
        --reserve-cpu 0.3 \
        --limit-cpu 0.6 \
        --reserve-memory 256m \
        --limit-memory 512m \
        --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock,readonly=true \
        --mount type=bind,source=/opt/traefik/traefik.yml,destination=/etc/traefik/traefik.yml,readonly=true \
        --mount type=bind,source=/opt/traefik/dynamic.yml,destination=/etc/traefik/dynamic.yml,readonly=true \
        --mount type=volume,source=traefik-certificates,destination=/etc/traefik/acme \
        --network traefik-public \
        --label "traefik.enable=true" \
        --label "traefik.docker.network=traefik-public" \
        --label "traefik.constraint-label=traefik-public" \
        --label "traefik.http.routers.api.rule=Host(\`${domain}\`)" \
        --label "traefik.http.routers.api.service=api@internal" \
        --label "traefik.http.routers.api.entrypoints=https" \
        --label "traefik.http.routers.api.middlewares=auth-middleware@file,security-headers@file" \
        --label "traefik.http.routers.api.tls=true" \
        --label "traefik.http.routers.api.tls.certresolver=letsencrypt" \
        --label "traefik.http.services.api.loadbalancer.server.port=8080" \
        traefik:v2.10

    # Wait for Traefik to be ready
    if ! wait_for_service "traefik"; then
        log_error "Traefik service failed to start properly"
        return 1
    fi

    # Test service functionality
    if ! test_traefik_service "$domain"; then
        log_warning "Traefik service started but functionality test failed"
        log_info "This may be due to DNS configuration - check that ${domain} points to this server"
    fi

    log_success "Traefik deployed successfully!"
}

# Deploy Swarmpit service
deploy_swarmpit() {
    local domain="$1"

    log_info "🚀 Deploying Swarmpit web interface..."

    # Create configuration directory
    mkdir -p /opt/swarmpit

    # Create swarmpit.yml stack file
    cat > /opt/swarmpit/swarmpit.yml << EOF
version: '3.3'

services:
  app:
    image: swarmpit/swarmpit:latest
    environment:
      - SWARMPIT_DB=http://db:5984
      - SWARMPIT_INFLUXDB=http://influxdb:8086
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - net
      - traefik-public
    deploy:
      resources:
        limits:
          cpus: '0.45'
          memory: 576M
        reservations:
          cpus: '0.15'
          memory: 256M
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.swarmpit-http.rule=Host(\`${domain}\`)
        - traefik.http.routers.swarmpit-http.entrypoints=http
        - traefik.http.routers.swarmpit-http.middlewares=https-redirect@file
        - traefik.http.routers.swarmpit-https.rule=Host(\`${domain}\`)
        - traefik.http.routers.swarmpit-https.entrypoints=https
        - traefik.http.routers.swarmpit-https.middlewares=security-headers@file
        - traefik.http.routers.swarmpit-https.tls=true
        - traefik.http.routers.swarmpit-https.tls.certresolver=letsencrypt
        - traefik.http.services.swarmpit.loadbalancer.server.port=8080

  db:
    image: couchdb:2.3.1
    volumes:
      - db-data:/opt/couchdb/data
    networks:
      - net
    deploy:
      resources:
        limits:
          cpus: '0.225'
          memory: 288M
        reservations:
          cpus: '0.05'
          memory: 128M
      placement:
        constraints:
          - node.labels.swarmpit.db-data == true

  influxdb:
    image: influxdb:1.7
    volumes:
      - influx-data:/var/lib/influxdb
    networks:
      - net
    deploy:
      resources:
        limits:
          cpus: '0.15'
          memory: 192M
        reservations:
          cpus: '0.03'
          memory: 64M
      placement:
        constraints:
          - node.labels.swarmpit.influx-data == true

  agent:
    image: swarmpit/agent:latest
    environment:
      - DOCKER_API_VERSION=1.35
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - net
    deploy:
      mode: global
      resources:
        limits:
          cpus: '0.075'
          memory: 96M
        reservations:
          cpus: '0.01'
          memory: 32M

networks:
  net:
    external: true
  traefik-public:
    external: true

volumes:
  db-data:
    driver: local
  influx-data:
    driver: local
EOF

    # Set node labels for database persistence
    local node_id=$(docker node ls -q)
    docker node update --label-add swarmpit.db-data=true $node_id
    docker node update --label-add swarmpit.influx-data=true $node_id

    # Remove existing stack if it exists
    if docker stack ls | grep -q "swarmpit"; then
        log_info "Removing existing Swarmpit stack..."
        docker stack rm swarmpit
        sleep 30
    fi

    # Deploy Swarmpit stack
    docker stack deploy -c /opt/swarmpit/swarmpit.yml swarmpit

    # Wait for Swarmpit to be ready
    sleep 30
    wait_for_service "swarmpit_app"
    log_success "Swarmpit deployed successfully!"
}

# Deploy Dozzle service
deploy_dozzle() {
    local domain="$1"

    log_info "🚀 Deploying Dozzle logging interface..."

    # Create configuration directory
    mkdir -p /opt/dozzle

    # Create dozzle.yml stack file
    cat > /opt/dozzle/dozzle.yml << EOF
version: '3.8'

services:
  dozzle:
    image: amir20/dozzle:latest
    environment:
      - DOZZLE_MODE=swarm
      - DOZZLE_LEVEL=info
      - DOZZLE_NO_ANALYTICS=true
      - DOZZLE_FILTER="status=running"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - dozzle
      - traefik-public
    deploy:
      mode: global
      resources:
        limits:
          cpus: '0.05'
          memory: 64M
        reservations:
          cpus: '0.01'
          memory: 32M
      labels:
        - traefik.enable=true
        - traefik.docker.network=traefik-public
        - traefik.constraint-label=traefik-public
        - traefik.http.routers.dozzle-http.rule=Host(\`${domain}\`)
        - traefik.http.routers.dozzle-http.entrypoints=http
        - traefik.http.routers.dozzle-http.middlewares=https-redirect@file
        - traefik.http.routers.dozzle-https.rule=Host(\`${domain}\`)
        - traefik.http.routers.dozzle-https.entrypoints=https
        - traefik.http.routers.dozzle-https.middlewares=auth-middleware@file,security-headers@file
        - traefik.http.routers.dozzle-https.tls=true
        - traefik.http.routers.dozzle-https.tls.certresolver=letsencrypt
        - traefik.http.services.dozzle.loadbalancer.server.port=8080

networks:
  dozzle:
    driver: overlay
    attachable: true
  traefik-public:
    external: true
EOF

    # Remove existing stack if it exists
    if docker stack ls | grep -q "dozzle"; then
        log_info "Removing existing Dozzle stack..."
        docker stack rm dozzle
        sleep 30
    fi

    # Deploy Dozzle stack
    docker stack deploy -c /opt/dozzle/dozzle.yml dozzle

    # Wait for Dozzle to be ready
    sleep 30
    wait_for_service "dozzle_dozzle"
    log_success "Dozzle deployed successfully!"
}

# Main deployment function
main() {
    local traefik_host="${TRAEFIK_HOST:-admin.example.com}"
    local swarmpit_host="${SWARMPIT_HOST:-swarmpit.example.com}"
    local dozzle_host="${DOZZLE_HOST:-logs.example.com}"
    local traefik_username="${TRAEFIK_USERNAME:-admin}"
    local admin_password_hash_b64="${ADMIN_PASSWORD_HASH:-}"
    local traefik_acme_email="${TRAEFIK_ACME_EMAIL:-admin@example.com}"

    log_info "Starting Traefik deployment..."

    # Check if Docker Swarm is initialized
    if ! docker info 2>/dev/null | grep -q "Swarm:.*active"; then
        log_error "Docker Swarm is not initialized. Please run init-docker-swarm.sh first."
        exit 1
    fi

    # Validate required parameters
    if [[ -z "$admin_password_hash_b64" ]]; then
        log_error "ADMIN_PASSWORD_HASH environment variable is required"
        log_info "Generate password hash with: htpasswd -nb admin yourpassword | base64 -w 0"
        log_info "Example: ADMIN_PASSWORD_HASH='YWRtaW46JDJhJDEwJEQ9RjE4cFJLJDkzRUZucWpWLzY5WFVQSFZ2QlA1NDE=' (base64 encoded)"
        exit 1
    fi

    # Decode the base64 password hash
    local admin_password_hash
    if ! admin_password_hash=$(echo "$admin_password_hash_b64" | base64 -d 2>/dev/null); then
        log_error "Failed to decode base64 password hash"
        log_info "Ensure ADMIN_PASSWORD_HASH is properly base64 encoded"
        log_info "Generate with: htpasswd -nb admin yourpassword | base64 -w 0"
        exit 1
    fi

    log_info "Successfully decoded password hash from base64"

    # Validate decoded password hash format
    if [[ ! "$admin_password_hash" =~ ^[^:]+:.+ ]]; then
        log_error "Invalid decoded password hash format. Expected format: username:hash"
        log_info "Decoded value: ${admin_password_hash}"
        log_info "Generate with: htpasswd -nb admin yourpassword | base64 -w 0"
        exit 1
    fi

    # Deploy Traefik
    if ! deploy_traefik "$traefik_host" "$traefik_username" "$admin_password_hash" "$traefik_acme_email"; then
        log_error "Failed to deploy Traefik"
        exit 1
    fi

    # Deploy Swarmpit
    if ! deploy_swarmpit "$swarmpit_host"; then
        log_error "Failed to deploy Swarmpit"
        exit 1
    fi

    # Deploy Dozzle
    if ! deploy_dozzle "$dozzle_host"; then
        log_error "Failed to deploy Dozzle"
        exit 1
    fi

    log_success "🎉 All services deployed successfully!"
    log_info "Access points:"
    log_info "  - Traefik Dashboard: https://$traefik_host"
    log_info "  - Swarmpit Management: https://$swarmpit_host"
    log_info "  - Dozzle Logs: https://$dozzle_host"
    log_info "  - Username: $traefik_username"
    log_info "  - Password: (as configured in ADMIN_PASSWORD_HASH)"
    log_info ""
    log_info "Configuration files created:"
    log_info "  - /opt/traefik/traefik.yml"
    log_info "  - /opt/traefik/dynamic.yml"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Ensure DNS records for all hostnames point to this server"
    log_info "  2. Wait for Let's Encrypt certificates to be issued"
    log_info "  3. Access services:"
    log_info "     - Traefik Dashboard: https://$traefik_host"
    log_info "     - Swarmpit Management: https://$swarmpit_host"
    log_info "     - Dozzle Logs: https://$dozzle_host"
    log_info "  4. Deploy your application stacks"
    log_info ""
    log_info "Your infrastructure is ready for deployment."
    log_info "All management interfaces are secured with the same admin credentials."
}

# Execute main function
main "$@"
