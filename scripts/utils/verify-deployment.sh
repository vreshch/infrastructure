#!/bin/bash

# verify-deployment.sh
# Comprehensive deployment verification script
# Checks DNS, SSH, Docker services, SSL certificates, and endpoint responsiveness

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err() { echo -e "${RED}❌ $1${NC}"; }
section() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

usage() {
  cat <<EOF
Usage: $0 <environment> [--ssh-key PATH]

Arguments:
  environment     Environment to verify (dev, staging, prod)
  --ssh-key PATH  Optional: Path to SSH private key (auto-detected from tfvars)

Example:
  $0 prod
  $0 dev --ssh-key ~/.ssh/dev-server_ed25519

This script verifies:
  1. DNS records propagation
  2. SSH connectivity to server
  3. Docker Swarm status
  4. Service health (Traefik, Swarmpit, Dozzle)
  5. SSL certificate issuance
  6. HTTP/HTTPS endpoint responsiveness
EOF
}

if [[ ${#@} -lt 1 ]]; then
  usage
  exit 1
fi

ENV="$1"
if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
  log_err "Invalid environment: $ENV"
  exit 1
fi

# Parse optional SSH key
SSH_KEY=""
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --ssh-key)
      SSH_KEY="$2"
      shift 2
      ;;
    *)
      log_err "Unknown option: $1"
      exit 1
      ;;
  esac
done

TFVARS_FILE="terraform/terraform.${ENV}.tfvars"
if [[ ! -f "$TFVARS_FILE" ]]; then
  log_err "Terraform vars file not found: $TFVARS_FILE"
  exit 1
fi

log "Reading configuration from $TFVARS_FILE..."

# Extract values from tfvars
DOMAIN=$(grep '^domain_name' "$TFVARS_FILE" | cut -d'"' -f2)
TRAEFIK_HOST=$(grep '^traefik_host' "$TFVARS_FILE" | cut -d'"' -f2)
SWARMPIT_HOST=$(grep '^swarmpit_host' "$TFVARS_FILE" | cut -d'"' -f2)
DOZZLE_HOST=$(grep '^dozzle_host' "$TFVARS_FILE" | cut -d'"' -f2)

# Get server IP from Terraform output
cd terraform || exit 1
SERVER_IP=$(terraform output -json 2>/dev/null | jq -r '.server_public_ip.value // empty')
cd - > /dev/null || exit 1
if [[ -z "$SERVER_IP" ]]; then
  log_err "Could not get server IP from Terraform output"
  log "Run 'cd terraform && terraform refresh' first"
  exit 1
fi

# Auto-detect SSH key if not provided
if [[ -z "$SSH_KEY" ]]; then
  SERVER_NAME=$(grep '^server_name' "$TFVARS_FILE" | cut -d'"' -f2)
  SSH_KEY="$HOME/.ssh/${SERVER_NAME}_ed25519"
  if [[ ! -f "$SSH_KEY" ]]; then
    log_err "SSH key not found at $SSH_KEY"
    log "Provide SSH key with --ssh-key option"
    exit 1
  fi
fi

log_ok "Configuration loaded"
echo "  Domain: $DOMAIN"
echo "  Server IP: $SERVER_IP"
echo "  SSH Key: $SSH_KEY"

ERRORS=0
WARNINGS=0

# ============================================================================
# SECTION 1: DNS Records Verification
# ============================================================================
section "DNS Records Verification"

check_dns() {
  local hostname="$1"
  local expected_ip="$2"
  
  # Try to resolve the hostname - get all IPs
  local resolved_ips
  resolved_ips=$(dig +short "$hostname" A)
  
  if [[ -z "$resolved_ips" ]]; then
    log_err "$hostname: Not resolved"
    ((ERRORS++))
    return 1
  elif echo "$resolved_ips" | grep -q "^${expected_ip}$"; then
    log_ok "$hostname → includes $expected_ip (+ $(echo "$resolved_ips" | wc -l) total)"
    return 0
  else
    log_warn "$hostname → $resolved_ips (expected $expected_ip not found)"
    ((WARNINGS++))
    return 1
  fi
}

# Check main domain
check_dns "$DOMAIN" "$SERVER_IP"

# Check subdomains (they should resolve to main domain or IP)
MAIN_IP=$(dig +short "$DOMAIN" A | tail -n1)
if [[ -n "$MAIN_IP" ]]; then
  for subdomain in "$TRAEFIK_HOST" "$SWARMPIT_HOST" "$DOZZLE_HOST"; do
    resolved=$(dig +short "$subdomain" | tail -n1)
    if [[ -n "$resolved" ]]; then
      log_ok "$subdomain → $resolved"
    else
      log_warn "$subdomain: Not resolved yet (DNS propagation in progress)"
      ((WARNINGS++))
    fi
  done
fi

# ============================================================================
# SECTION 2: SSH Connectivity
# ============================================================================
section "SSH Connectivity"

if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 root@"$SERVER_IP" "echo 'SSH connection successful'" &>/dev/null; then
  log_ok "SSH connection to root@$SERVER_IP successful"
else
  log_err "Cannot connect via SSH to root@$SERVER_IP"
  ((ERRORS++))
  exit 1
fi

# ============================================================================
# SECTION 3: Docker Swarm Status
# ============================================================================
section "Docker Swarm Status"

SWARM_STATUS=$(ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker info --format '{{.Swarm.LocalNodeState}}'" 2>/dev/null || echo "error")
if [[ "$SWARM_STATUS" == "active" ]]; then
  log_ok "Docker Swarm is active"
else
  log_err "Docker Swarm is not active (status: $SWARM_STATUS)"
  ((ERRORS++))
fi

# Check node status
NODE_INFO=$(ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker node ls --format '{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}'" 2>/dev/null || echo "")
if [[ -n "$NODE_INFO" ]]; then
  IFS=$'\t' read -r status availability manager <<< "$NODE_INFO"
  if [[ "$status" == "Ready" && "$availability" == "Active" ]]; then
    log_ok "Swarm node: $status, $availability, $manager"
  else
    log_warn "Swarm node: $status, $availability, $manager"
    ((WARNINGS++))
  fi
fi

# ============================================================================
# SECTION 4: Service Health
# ============================================================================
section "Docker Services"

SERVICES=$(ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker service ls --format '{{.Name}}\t{{.Replicas}}'" 2>/dev/null || echo "")
if [[ -z "$SERVICES" ]]; then
  log_err "No services found"
  ((ERRORS++))
else
  while IFS=$'\t' read -r name replicas; do
    if [[ "$replicas" =~ ^([0-9]+)/([0-9]+) ]]; then
      running="${BASH_REMATCH[1]}"
      desired="${BASH_REMATCH[2]}"
      if [[ "$running" == "$desired" ]]; then
        log_ok "$name: $replicas"
      else
        log_warn "$name: $replicas (not all replicas running)"
        ((WARNINGS++))
      fi
    else
      log_ok "$name: $replicas"
    fi
  done <<< "$SERVICES"
fi

# Check specific service logs for errors
section "Service Logs Check"

for service in traefik swarmpit_app dozzle_dozzle; do
  log "Checking $service logs for recent errors..."
  ERROR_COUNT=$(ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker service logs --tail 100 $service 2>/dev/null | grep -iE 'error|fatal|failed' | wc -l" || echo "0")
  if [[ "$ERROR_COUNT" -gt 0 ]]; then
    log_warn "$service has $ERROR_COUNT error messages in recent logs"
    ((WARNINGS++))
  else
    log_ok "$service: No recent errors"
  fi
done

# ============================================================================
# SECTION 5: SSL Certificates
# ============================================================================
section "SSL Certificates"

log "Checking Traefik ACME certificates..."
CERT_COUNT=$(ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker exec \$(docker ps -qf name=traefik) cat /letsencrypt/acme.json 2>/dev/null | jq -r '.default.Certificates // [] | length' 2>/dev/null" || echo "0")

if [[ "$CERT_COUNT" -gt 0 ]]; then
  log_ok "SSL certificates issued: $CERT_COUNT certificate(s)"
  
  # List certificates
  ssh -i "$SSH_KEY" root@"$SERVER_IP" "docker exec \$(docker ps -qf name=traefik) cat /letsencrypt/acme.json 2>/dev/null | jq -r '.default.Certificates[].domain.main' 2>/dev/null" | while read -r cert_domain; do
    log "  Certificate for: $cert_domain"
  done
else
  log_warn "No SSL certificates found yet (may still be in progress)"
  log "Check Traefik logs: ssh root@$SERVER_IP 'docker service logs traefik | grep -i acme'"
  ((WARNINGS++))
fi

# ============================================================================
# SECTION 6: HTTP/HTTPS Endpoint Tests
# ============================================================================
section "Endpoint Responsiveness"

check_endpoint() {
  local url="$1"
  local description="$2"
  local auth="${3:-}"
  
  local curl_opts=(-s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 15)
  if [[ -n "$auth" ]]; then
    curl_opts+=(-u "$auth")
  fi
  
  local http_code
  http_code=$(curl "${curl_opts[@]}" "$url" 2>/dev/null || echo "000")
  
  case "$http_code" in
    000)
      log_err "$description: Connection failed"
      ((ERRORS++))
      ;;
    200|301|302)
      log_ok "$description: HTTP $http_code"
      ;;
    401)
      log_ok "$description: HTTP $http_code (auth required - expected)"
      ;;
    404)
      log_warn "$description: HTTP $http_code (not found)"
      ((WARNINGS++))
      ;;
    5*)
      log_err "$description: HTTP $http_code (server error)"
      ((ERRORS++))
      ;;
    *)
      log_warn "$description: HTTP $http_code"
      ((WARNINGS++))
      ;;
  esac
}

# Check direct IP
log "Testing direct IP access..."
check_endpoint "http://$SERVER_IP" "Direct HTTP"

# Check domain endpoints (only if DNS is resolved)
if dig +short "$DOMAIN" | grep -q "$SERVER_IP"; then
  log "Testing domain endpoints..."
  check_endpoint "https://$TRAEFIK_HOST" "Traefik Dashboard"
  check_endpoint "https://$SWARMPIT_HOST" "Swarmpit UI"
  check_endpoint "https://$DOZZLE_HOST" "Dozzle Logs"
else
  log_warn "Skipping HTTPS endpoint tests - DNS not fully propagated"
  log "Wait 5-10 minutes and run this script again"
  ((WARNINGS++))
fi

# ============================================================================
# SUMMARY
# ============================================================================
section "Verification Summary"

echo ""
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  log_ok "✨ All checks passed! Deployment is healthy."
  echo ""
  echo "Access your infrastructure:"
  echo "  Traefik:  https://$TRAEFIK_HOST"
  echo "  Swarmpit: https://$SWARMPIT_HOST"
  echo "  Dozzle:   https://$DOZZLE_HOST"
  echo "  SSH:      ssh -i $SSH_KEY root@$SERVER_IP"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  log_warn "Deployment is mostly healthy with $WARNINGS warning(s)"
  echo ""
  echo "Common warnings:"
  echo "  - DNS propagation: Wait 5-10 minutes and re-run verification"
  echo "  - SSL certificates: Issued after DNS propagates (~5-10 min)"
  exit 0
else
  log_err "Deployment has $ERRORS error(s) and $WARNINGS warning(s)"
  echo ""
  echo "Troubleshooting:"
  echo "  1. Check Terraform state: cd terraform && terraform refresh"
  echo "  2. Check service logs: ssh root@$SERVER_IP 'docker service ls'"
  echo "  3. Review Traefik logs: ssh root@$SERVER_IP 'docker service logs traefik'"
  exit 1
fi
