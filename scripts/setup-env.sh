#!/bin/bash

# Quick Setup Script
# 
# This script helps you quickly set up a new environment configuration
# from the example template.

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
    echo "   🚀 Infrastructure Setup"
    echo "=================================================="
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 <environment>"
    echo ""
    echo "Environments:"
    echo "  dev        - Development environment"
    echo "  staging    - Staging environment"
    echo "  prod       - Production environment"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 prod"
}

# Validate arguments
if [[ $# -ne 1 ]]; then
    show_usage
    exit 1
fi

ENVIRONMENT="$1"

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Use 'dev', 'staging', or 'prod'"
fi

show_banner

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$PROJECT_DIR/infrastructure"
TARGET_FILE="$INFRA_DIR/terraform.$ENVIRONMENT.tfvars"
EXAMPLE_FILE="$INFRA_DIR/terraform.example.tfvars"

log_info "Setting up $ENVIRONMENT environment configuration..."
log_info "Target file: $TARGET_FILE"

# Change to infrastructure directory
cd "$INFRA_DIR" || log_error "Cannot change to infrastructure directory: $INFRA_DIR"

# Check if example file exists
if [[ ! -f "$EXAMPLE_FILE" ]]; then
    log_error "Example file not found: $EXAMPLE_FILE"
fi

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

# Copy example file
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

# Show next steps
echo ""
log_info "🎯 Next Steps:"
echo ""
echo "1. 🔧 Edit the configuration file:"
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
echo "   terraform init"
echo "   terraform plan -var-file=\"terraform.$ENVIRONMENT.tfvars\""
echo "   terraform apply -var-file=\"terraform.$ENVIRONMENT.tfvars\""
echo ""
echo "4. 📖 For detailed instructions, see:"
echo "   docs/deployment-guide.md"
echo ""

if [[ "$ENVIRONMENT" == "prod" ]]; then
    log_warning "⚠️  Production Environment"
    echo "   - Use strong, unique credentials"
    echo "   - Enable MFA on all accounts"
    echo "   - Use dedicated SSH keys"
    echo "   - Consider staging deployment first"
    echo ""
fi

log_success "✨ $ENVIRONMENT environment setup complete!"
log_info "📁 Configuration file: $TARGET_FILE"
