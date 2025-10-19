#!/bin/bash

# setup-fill-tfvars.sh
# Interactive script that collects environment values and writes terraform/terraform.<env>.tfvars
# - Validates inputs
# - Generates bcrypt htpasswd via htpasswd or Docker
# - Base64-encodes the htpasswd entry for Terraform variable

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_ok() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

usage(){
  cat <<EOF
Usage: $0 <environment>
Environments: dev | staging | prod
Example: $0 prod
This will create or overwrite: terraform/terraform.<env>.tfvars
EOF
}

if [[ ${#@} -lt 1 ]]; then
  usage
  exit 1
fi

ENV="$1"
if [[ "$ENV" != "dev" && "$ENV" != "staging" && "$ENV" != "prod" ]]; then
  log_err "Invalid environment: $ENV"
fi

# Defaults per env
case "$ENV" in
  dev)
    DEFAULT_DOMAIN="dev.example.com"
    DEFAULT_SERVER_NAME="dev-server"
    DEFAULT_SERVER_TYPE="cx23"
    DEFAULT_LOCATION="nbg1"
    TF_ENVIRONMENT="development"
    ;;
  staging)
    DEFAULT_DOMAIN="staging.example.com"
    DEFAULT_SERVER_NAME="staging-server"
    DEFAULT_SERVER_TYPE="cx33"
    DEFAULT_LOCATION="fsn1"
    TF_ENVIRONMENT="staging"
    ;;
  prod)
    DEFAULT_DOMAIN="example.com"
    DEFAULT_SERVER_NAME="prod-server"
    DEFAULT_SERVER_TYPE="cx43"
    DEFAULT_LOCATION="fsn1"
    TF_ENVIRONMENT="production"
    ;;
esac

prompt(){
  local msg="$1"; local def="$2"; local secret=${3:-0}
  if [[ -n "$def" ]]; then
    echo -n -e "${YELLOW}${msg} [${def}]: ${NC}" >&2
  else
    echo -n -e "${YELLOW}${msg}: ${NC}" >&2
  fi
  if [[ "$secret" -eq 1 ]]; then
    read -rs val; echo >&2
  else
    read -r val
  fi
  if [[ -z "$val" ]]; then
    echo "$def"
  else
    echo "$val"
  fi
}

validate_domain(){
  local d="$1"
  if [[ "$d" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
    return 0
  fi
  return 1
}

VALID_TYPES=("cx11" "cx21" "cx22" "cx23" "cx31" "cx32" "cx33" "cx41" "cx42" "cx43" "cx51" "cx52" "cx53")
validate_server_type(){
  local t="$1"
  for v in "${VALID_TYPES[@]}"; do [[ "$v" == "$t" ]] && return 0; done
  return 1
}

# Collect values
DOMAIN=$(prompt "Domain name" "$DEFAULT_DOMAIN")
if ! validate_domain "$DOMAIN"; then log_err "Invalid domain format: $DOMAIN"; fi

TRAEFIK_HOST=$(prompt "Traefik hostname" "admin.$DOMAIN")
SWARMPIT_HOST=$(prompt "Swarmpit hostname" "swarmpit.$DOMAIN")
DOZZLE_HOST=$(prompt "Dozzle hostname" "logs.$DOMAIN")

ACME_EMAIL=$(prompt "Let's Encrypt email" "admin@$DOMAIN")
# basic email validation
if [[ ! "$ACME_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
  log_err "Invalid email: $ACME_EMAIL"
fi

SERVER_NAME=$(prompt "Server name" "$DEFAULT_SERVER_NAME")
SERVER_TYPE=$(prompt "Server type (e.g. cx33)" "$DEFAULT_SERVER_TYPE")
if ! validate_server_type "$SERVER_TYPE"; then
  log_err "Invalid server type: $SERVER_TYPE"
fi
LOCATION=$(prompt "Datacenter location (nbg1/fsn1/hel1)" "$DEFAULT_LOCATION")

log "Provide Hetzner API tokens (will not be stored in git)."
HETZNER_TOKEN=$(prompt "Hetzner Cloud API token" "")
if [[ -z "$HETZNER_TOKEN" ]]; then log_err "Hetzner Cloud API token required"; fi
if [[ ${#HETZNER_TOKEN} -lt 20 ]]; then log_warn "Token looks short; verify it in Hetzner Console"; fi

HETZNER_DNS_TOKEN=$(prompt "Hetzner DNS API token" "")
if [[ -z "$HETZNER_DNS_TOKEN" ]]; then log_err "Hetzner DNS API token required"; fi
if [[ ${#HETZNER_DNS_TOKEN} -lt 20 ]]; then log_warn "DNS token looks short; verify it"; fi

HETZNER_DNS_ZONE_ID=$(prompt "Hetzner DNS Zone ID" "")
if [[ -z "$HETZNER_DNS_ZONE_ID" ]]; then log_err "DNS Zone ID required"; fi

# SSH keys
SSH_PUB_PATH_DEFAULT="$HOME/.ssh/${SERVER_NAME}_ed25519.pub"
SSH_PRIV_PATH_DEFAULT="$HOME/.ssh/${SERVER_NAME}_ed25519"
SSH_PUBLIC_PATH=$(prompt "Path to SSH public key" "$SSH_PUB_PATH_DEFAULT")
SSH_PRIVATE_PATH=$(prompt "Path to SSH private key" "$SSH_PRIV_PATH_DEFAULT")
SSH_PUBLIC_PATH="${SSH_PUBLIC_PATH/#\~/$HOME}"
SSH_PRIVATE_PATH="${SSH_PRIVATE_PATH/#\~/$HOME}"

# Check if SSH keys exist, if not offer to generate them
if [[ ! -f "$SSH_PUBLIC_PATH" ]] || [[ ! -f "$SSH_PRIVATE_PATH" ]]; then
  log_warn "SSH keys not found at $SSH_PUBLIC_PATH"
  echo
  choice=$(prompt "Would you like to generate SSH keys now? (y/n)" "y")
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    # Extract key name from path (remove .pub and _ed25519)
    KEY_NAME=$(basename "$SSH_PRIVATE_PATH" | sed 's/_ed25519$//')
    log "Generating SSH key pair: $KEY_NAME"
    
    # Check if generate-ssh-keys.sh exists
    if [[ -x "./scripts/utils/generate-ssh-keys.sh" ]]; then
      ./scripts/utils/generate-ssh-keys.sh "$KEY_NAME" ed25519 || log_err "Failed to generate SSH keys"
      log_ok "SSH keys generated successfully"
    else
      log "Generating SSH keys manually..."
      ssh-keygen -t ed25519 -f "$SSH_PRIVATE_PATH" -C "${KEY_NAME}-$(date +%Y%m%d)" -N "" || log_err "Failed to generate SSH keys"
      log_ok "SSH keys generated at $SSH_PRIVATE_PATH"
    fi
  else
    log_err "SSH keys are required. Please generate them and run the script again."
  fi
fi

# Read SSH keys
if [[ -f "$SSH_PUBLIC_PATH" ]]; then
  SSH_PUBLIC=$(cat "$SSH_PUBLIC_PATH")
else
  log_err "SSH public key not found at $SSH_PUBLIC_PATH"
fi
if [[ -f "$SSH_PRIVATE_PATH" ]]; then
  SSH_PRIVATE=$(cat "$SSH_PRIVATE_PATH")
else
  log_err "SSH private key not found at $SSH_PRIVATE_PATH"
fi

# Admin password (user must enter)
echo >&2
echo "Admin password for basic auth:" >&2
log_warn "This password will be used to access Traefik, Swarmpit, and Dozzle dashboards."
ADMIN_PASSWORD=$(prompt "Enter admin password (min 8 characters)" "" 1)
if [[ -z "$ADMIN_PASSWORD" ]]; then
  log_err "Password cannot be empty"
fi
if [[ ${#ADMIN_PASSWORD} -lt 8 ]]; then
  log_err "Password must be at least 8 characters long"
fi

# Generate bcrypt htpasswd entry
generate_htpasswd() {
  local user="$1"; local pass="$2"; local out
  if command -v htpasswd &>/dev/null; then
    out=$(htpasswd -nbB "$user" "$pass" 2>/dev/null) || return 1
    echo "$out"
  elif command -v docker &>/dev/null; then
    out=$(docker run --rm httpd:2.4-alpine htpasswd -nbB "$user" "$pass" 2>/dev/null) || return 1
    echo "$out"
  else
    return 1
  fi
}

log "Generating bcrypt htpasswd entry (this requires htpasswd or Docker)..."
HTPASSWD_ENTRY=$(generate_htpasswd admin "$ADMIN_PASSWORD") || log_err "Failed to generate htpasswd entry. Install apache2-utils or Docker."
log_ok "htpasswd entry generated"

# Base64 encode the full htpasswd entry
ADMIN_PASSWORD_HASH_BASE64=$(echo -n "$HTPASSWD_ENTRY" | base64 -w0)

# Build tfvars file
TFVARS_FILE="terraform/terraform.${ENV}.tfvars"
mkdir -p terraform
cat > "$TFVARS_FILE" <<EOF
# Terraform Configuration for $ENV environment (generated by setup-fill-tfvars.sh)

# HETZNER CREDENTIALS
hetzner_token = "$HETZNER_TOKEN"
hetzner_dns_token = "$HETZNER_DNS_TOKEN"
hetzner_dns_zone_id = "$HETZNER_DNS_ZONE_ID"

# DOMAIN CONFIGURATION
domain_name = "$DOMAIN"
traefik_host = "$TRAEFIK_HOST"
swarmpit_host = "$SWARMPIT_HOST"
dozzle_host = "$DOZZLE_HOST"
traefik_acme_email = "$ACME_EMAIL"

# SERVER CONFIGURATION
server_name = "$SERVER_NAME"
server_type = "$SERVER_TYPE"
location = "$LOCATION"
environment = "${TF_ENVIRONMENT}"

# SSH KEYS
ssh_public_key = <<-EOT
$SSH_PUBLIC
EOT

ssh_private_key = <<-EOT
$SSH_PRIVATE
EOT

# AUTHENTICATION
admin_password_hash = "$ADMIN_PASSWORD_HASH_BASE64"

# Enable Docker Swarm
enable_docker_swarm = true

EOF

chmod 600 "$TFVARS_FILE"
log_ok "Wrote configuration to $TFVARS_FILE (permissions 600)"

echo
log_ok "Summary"
echo "Environment: $ENV"
echo "Domain: $DOMAIN"
echo "Server: $SERVER_NAME ($SERVER_TYPE) @ $LOCATION"
echo "Terraform var file: $TFVARS_FILE"
echo "Admin username: admin"
echo "Admin password (keep secure): $ADMIN_PASSWORD"

echo
log "Next steps:"
echo "  cd terraform && terraform init"
echo "  terraform plan -var-file=\"terraform.${ENV}.tfvars\""
echo "  terraform apply -var-file=\"terraform.${ENV}.tfvars\""

exit 0
SCRIPT_EOF
