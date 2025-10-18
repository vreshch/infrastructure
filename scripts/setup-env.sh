#!/bin/bash

# Interactive Environment Setup Script
# 
# This script helps you quickly set up a new environment configuration
# with interactive prompts for all required values.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

show_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "   🚀 Interactive Infrastructure Setup"
    echo "=================================================="
    echo -e "${NC}"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        echo -ne "${YELLOW}${prompt} [${default}]: ${NC}"
    else
        echo -ne "${YELLOW}${prompt}: ${NC}"
    fi
    
    read -r result
    
    if [[ -z "$result" && -n "$default" ]]; then
        echo "$default"
    else
        echo "$result"
    fi
}

prompt_secret() {
    local prompt="$1"
    local result
    
    echo -ne "${YELLOW}${prompt}: ${NC}"
    read -rs result
    echo ""
    echo "$result"
}

validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

show_usage() {
    echo "Usage: $0 <environment> [--interactive | --from-template]"
    echo ""
    echo "Environments:"
    echo "  dev        - Development environment"
    echo "  staging    - Staging environment"
    echo "  prod       - Production environment"
    echo ""
    echo "Modes:"
    echo "  --interactive    - Interactive prompts for all values (default)"
    echo "  --from-template  - Copy from template with example values"
    echo ""
    echo "Examples:"
    echo "  $0 dev                    # Interactive setup for dev"
    echo "  $0 prod --interactive     # Interactive setup for prod"
    echo "  $0 dev --from-template    # Copy template for dev"
}

# Validate arguments
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

ENVIRONMENT="$1"
MODE="${2:---interactive}"

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Use 'dev', 'staging', or 'prod'"
fi

# Validate mode
if [[ "$MODE" != "--interactive" && "$MODE" != "--from-template" ]]; then
    log_error "Invalid mode: $MODE. Use '--interactive' or '--from-template'"
fi

show_banner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/configs"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
TARGET_FILE="$TERRAFORM_DIR/terraform.$ENVIRONMENT.tfvars"

# Use the appropriate example file based on environment
if [[ -f "$CONFIG_DIR/$ENVIRONMENT.example.tfvars" ]]; then
    EXAMPLE_FILE="$CONFIG_DIR/$ENVIRONMENT.example.tfvars"
else
    EXAMPLE_FILE="$CONFIG_DIR/terraform.example.tfvars"
fi

log_info "Setting up $ENVIRONMENT environment configuration..."
log_info "Target file: $TARGET_FILE"

# Change to terraform directory
cd "$TERRAFORM_DIR" || log_error "Cannot change to terraform directory: $TERRAFORM_DIR"

# Check if target file already exists
if [[ -f "$TARGET_FILE" ]]; then
    log_warning "Configuration file already exists: $TARGET_FILE"
    echo -n "Do you want to overwrite it? (y/N): "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
fi

# Handle different modes
if [[ "$MODE" == "--from-template" ]]; then
    # Old behavior: just copy the template
    log_step "Creating configuration file from template..."
    cp "$EXAMPLE_FILE" "$TARGET_FILE"
    
    # Set appropriate permissions
    chmod 600 "$TARGET_FILE"
    log_success "Configuration file created with secure permissions"
    
    # Update environment-specific values
    log_step "Updating environment-specific values..."
    
    case "$ENVIRONMENT" in
        "dev")
            sed -i 's/domain_name = "your-domain.com"/domain_name = "dev.example.com"/' "$TARGET_FILE"
            sed -i 's/server_name = "my-server"/server_name = "dev-server"/' "$TARGET_FILE"
            sed -i 's/environment = "development"/environment = "development"/' "$TARGET_FILE"
            sed -i 's/traefik_host = "admin.YOUR_DOMAIN.com"/traefik_host = "admin.dev.example.com"/' "$TARGET_FILE"
            sed -i 's/swarmpit_host = "swarmpit.YOUR_DOMAIN.com"/swarmpit_host = "swarmpit.dev.example.com"/' "$TARGET_FILE"
            sed -i 's/dozzle_host = "logs.YOUR_DOMAIN.com"/dozzle_host = "logs.dev.example.com"/' "$TARGET_FILE"
            sed -i 's/traefik_acme_email = "admin@YOUR_DOMAIN.com"/traefik_acme_email = "admin@example.com"/' "$TARGET_FILE"
            ;;
        "staging")
            sed -i 's/domain_name = "your-domain.com"/domain_name = "staging.example.com"/' "$TARGET_FILE"
            sed -i 's/server_name = "my-server"/server_name = "staging-server"/' "$TARGET_FILE"
            sed -i 's/environment = "development"/environment = "staging"/' "$TARGET_FILE"
            sed -i 's/traefik_host = "admin.YOUR_DOMAIN.com"/traefik_host = "admin.staging.example.com"/' "$TARGET_FILE"
            sed -i 's/swarmpit_host = "swarmpit.YOUR_DOMAIN.com"/swarmpit_host = "swarmpit.staging.example.com"/' "$TARGET_FILE"
            sed -i 's/dozzle_host = "logs.YOUR_DOMAIN.com"/dozzle_host = "logs.staging.example.com"/' "$TARGET_FILE"
            sed -i 's/traefik_acme_email = "admin@YOUR_DOMAIN.com"/traefik_acme_email = "admin@example.com"/' "$TARGET_FILE"
            ;;
        "prod")
            sed -i 's/domain_name = "your-domain.com"/domain_name = "example.com"/' "$TARGET_FILE"
            sed -i 's/server_name = "my-server"/server_name = "prod-server"/' "$TARGET_FILE"
            sed -i 's/environment = "development"/environment = "production"/' "$TARGET_FILE"
            sed -i 's/traefik_host = "admin.YOUR_DOMAIN.com"/traefik_host = "admin.example.com"/' "$TARGET_FILE"
            sed -i 's/swarmpit_host = "swarmpit.YOUR_DOMAIN.com"/swarmpit_host = "swarmpit.example.com"/' "$TARGET_FILE"
            sed -i 's/dozzle_host = "logs.YOUR_DOMAIN.com"/dozzle_host = "logs.example.com"/' "$TARGET_FILE"
            sed -i 's/traefik_acme_email = "admin@YOUR_DOMAIN.com"/traefik_acme_email = "admin@example.com"/' "$TARGET_FILE"
            ;;
    esac
    
    log_success "Environment-specific values updated"
else
    # Interactive mode
    log_info "🎯 Interactive Configuration Mode"
    echo ""
    
    # Set defaults based on environment
    case "$ENVIRONMENT" in
        "dev")
            DEFAULT_DOMAIN="dev.example.com"
            DEFAULT_SERVER="dev-server"
            DEFAULT_ENV="development"
            DEFAULT_SERVER_TYPE="cx22"
            ;;
        "staging")
            DEFAULT_DOMAIN="staging.example.com"
            DEFAULT_SERVER="staging-server"
            DEFAULT_ENV="staging"
            DEFAULT_SERVER_TYPE="cx22"
            ;;
        "prod")
            DEFAULT_DOMAIN="example.com"
            DEFAULT_SERVER="prod-server"
            DEFAULT_ENV="production"
            DEFAULT_SERVER_TYPE="cx32"
            ;;
    esac
    
    # Prompt for configuration values
    log_step "Domain Configuration"
    while true; do
        DOMAIN=$(prompt_input "Enter your domain name" "$DEFAULT_DOMAIN")
        if validate_domain "$DOMAIN"; then
            break
        else
            log_error "Invalid domain format. Please try again."
        fi
    done
    
    TRAEFIK_HOST=$(prompt_input "Traefik dashboard hostname" "admin.$DOMAIN")
    SWARMPIT_HOST=$(prompt_input "Swarmpit management hostname" "swarmpit.$DOMAIN")
    DOZZLE_HOST=$(prompt_input "Dozzle logs hostname" "logs.$DOMAIN")
    
    while true; do
        ACME_EMAIL=$(prompt_input "Let's Encrypt email" "admin@${DOMAIN#*.}")
        if validate_email "$ACME_EMAIL"; then
            break
        else
            log_error "Invalid email format. Please try again."
        fi
    done
    
    echo ""
    log_step "Server Configuration"
    SERVER_NAME=$(prompt_input "Server name" "$DEFAULT_SERVER")
    SERVER_TYPE=$(prompt_input "Server type (cx11/cx21/cx22/cx31/cx32/cx41/cx42/cx51/cx52)" "$DEFAULT_SERVER_TYPE")
    LOCATION=$(prompt_input "Datacenter location (nbg1/fsn1/hel1/ash/hil)" "nbg1")
    
    echo ""
    log_step "Hetzner Credentials"
    log_info "📖 Get your tokens from: https://console.hetzner.cloud/"
    HETZNER_TOKEN=$(prompt_secret "Hetzner Cloud API token")
    HETZNER_DNS_TOKEN=$(prompt_secret "Hetzner DNS API token")
    HETZNER_DNS_ZONE_ID=$(prompt_input "Hetzner DNS Zone ID")
    
    echo ""
    log_step "SSH Configuration"
    log_info "💡 Tip: Run './scripts/utils/generate-ssh-keys.sh' to create new keys"
    
    # Check if user wants to use existing keys
    echo -ne "${YELLOW}Do you have SSH keys ready? (y/N): ${NC}"
    read -r has_keys
    
    if [[ "$has_keys" == "y" || "$has_keys" == "Y" ]]; then
        SSH_PUBLIC_KEY_PATH=$(prompt_input "Path to SSH public key" "~/.ssh/id_ed25519.pub")
        SSH_PRIVATE_KEY_PATH=$(prompt_input "Path to SSH private key" "~/.ssh/id_ed25519")
        
        # Expand tilde
        SSH_PUBLIC_KEY_PATH="${SSH_PUBLIC_KEY_PATH/#\~/$HOME}"
        SSH_PRIVATE_KEY_PATH="${SSH_PRIVATE_KEY_PATH/#\~/$HOME}"
        
        if [[ -f "$SSH_PUBLIC_KEY_PATH" ]]; then
            SSH_PUBLIC_KEY=$(cat "$SSH_PUBLIC_KEY_PATH")
        else
            log_error "Public key file not found: $SSH_PUBLIC_KEY_PATH"
        fi
        
        if [[ -f "$SSH_PRIVATE_KEY_PATH" ]]; then
            SSH_PRIVATE_KEY=$(cat "$SSH_PRIVATE_KEY_PATH")
        else
            log_error "Private key file not found: $SSH_PRIVATE_KEY_PATH"
        fi
    else
        log_warning "You'll need to generate SSH keys and update the config file manually"
        SSH_PUBLIC_KEY="YOUR_SSH_PUBLIC_KEY"
        SSH_PRIVATE_KEY="YOUR_SSH_PRIVATE_KEY"
    fi
    
    echo ""
    log_step "Admin Authentication"
    log_info "💡 Tip: Run './scripts/utils/generate-password.sh' to create a hash"
    echo -ne "${YELLOW}Do you have an htpasswd hash ready? (y/N): ${NC}"
    read -r has_hash
    
    if [[ "$has_hash" == "y" || "$has_hash" == "Y" ]]; then
        ADMIN_PASSWORD_HASH=$(prompt_secret "Admin password hash (bcrypt from htpasswd)")
    else
        log_warning "You'll need to generate a password hash and update the config file manually"
        ADMIN_PASSWORD_HASH="YOUR_ADMIN_PASSWORD_HASH"
    fi
    
    # Create configuration file
    log_step "Creating configuration file..."
    
    cat > "$TARGET_FILE" <<EOF
# Terraform Configuration for $ENVIRONMENT Environment
# Generated by setup-env.sh on $(date)

# ============================================================================
# HETZNER CREDENTIALS
# ============================================================================

hetzner_token = "$HETZNER_TOKEN"

hetzner_dns_token = "$HETZNER_DNS_TOKEN"

hetzner_dns_zone_id = "$HETZNER_DNS_ZONE_ID"

# ============================================================================
# DOMAIN CONFIGURATION
# ============================================================================

domain_name = "$DOMAIN"

traefik_host = "$TRAEFIK_HOST"

swarmpit_host = "$SWARMPIT_HOST"

dozzle_host = "$DOZZLE_HOST"

traefik_acme_email = "$ACME_EMAIL"

# ============================================================================
# SERVER CONFIGURATION
# ============================================================================

server_name = "$SERVER_NAME"

server_type = "$SERVER_TYPE"

location = "$LOCATION"

environment = "$DEFAULT_ENV"

# ============================================================================
# SSH CONFIGURATION
# ============================================================================

ssh_public_key = <<-EOT
$SSH_PUBLIC_KEY
EOT

ssh_private_key = <<-EOT
$SSH_PRIVATE_KEY
EOT

# ============================================================================
# AUTHENTICATION
# ============================================================================

admin_password_hash = "$ADMIN_PASSWORD_HASH"

# ============================================================================
# OPTIONAL: Additional DNS Records
# ============================================================================

# additional_cname_records = [
#   {
#     name   = "www"
#     target = "$DOMAIN."
#   }
# ]

# additional_a_records = [
#   {
#     name  = "api"
#     value = "YOUR_SERVER_IP"
#   }
# ]
EOF
    
    chmod 600 "$TARGET_FILE"
    log_success "Configuration file created with secure permissions"
fi

# Show next steps
echo ""
log_info "🎯 Next Steps:"
echo ""

if [[ "$MODE" == "--interactive" ]]; then
    echo "1. � Review the configuration file:"
    echo "   cat $TARGET_FILE"
    echo ""
    echo "2. 🚀 Deploy infrastructure:"
    echo "   cd $TERRAFORM_DIR"
    echo "   terraform init"
    echo "   terraform plan -var-file=\"terraform.$ENVIRONMENT.tfvars\""
    echo "   terraform apply -var-file=\"terraform.$ENVIRONMENT.tfvars\""
else
    echo "1. �🔧 Edit the configuration file:"
    echo "   nano $TARGET_FILE"
    echo ""
    echo "2. 🔑 Required values to configure:"
    echo "   - hetzner_dns_zone_id"
    echo "   - hetzner_dns_token"
    echo "   - hetzner_token"
    echo "   - ssh_public_key"
    echo "   - ssh_private_key"
    echo "   - admin_password_hash"
    echo ""
    echo "3. 🚀 Deploy infrastructure:"
    echo "   cd $TERRAFORM_DIR"
    echo "   terraform init"
    echo "   terraform plan -var-file=\"terraform.$ENVIRONMENT.tfvars\""
    echo "   terraform apply -var-file=\"terraform.$ENVIRONMENT.tfvars\""
fi
echo ""
echo "4. 📖 For detailed instructions, see README.md"
echo ""

if [[ "$ENVIRONMENT" == "prod" ]]; then
    log_warning "⚠️  Production Environment Security Checklist"
    echo "   ✓ Use strong, unique credentials"
    echo "   ✓ Enable MFA on all accounts"
    echo "   ✓ Use dedicated SSH keys (not shared with dev/staging)"
    echo "   ✓ Review firewall rules"
    echo "   ✓ Consider staging deployment first"
    echo "   ✓ Set up monitoring and backups"
    echo ""
fi

log_success "✨ $ENVIRONMENT environment setup complete!"
log_info "📁 Configuration file: $TARGET_FILE"
