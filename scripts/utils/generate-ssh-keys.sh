#!/bin/bash

# SSH Key Generation Utility
#
# This script helps generate SSH key pairs for infrastructure deployment
# with proper permissions and format.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "   🔑 SSH Key Generation Utility"
    echo "=================================================="
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 [key-name] [key-type]"
    echo ""
    echo "Arguments:"
    echo "  key-name   - Name for the SSH key (default: deploy)"
    echo "  key-type   - Type of key: ed25519 or rsa (default: ed25519)"
    echo ""
    echo "Examples:"
    echo "  $0                        # Create ~/.ssh/deploy_ed25519"
    echo "  $0 prod                   # Create ~/.ssh/prod_ed25519"
    echo "  $0 deploy rsa             # Create ~/.ssh/deploy_rsa"
}

show_banner

# Parse arguments
KEY_NAME="${1:-deploy}"
KEY_TYPE="${2:-ed25519}"

# Validate key type
if [[ "$KEY_TYPE" != "ed25519" && "$KEY_TYPE" != "rsa" ]]; then
    log_error "Invalid key type: $KEY_TYPE. Use 'ed25519' or 'rsa'"
fi

# Determine key paths
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/${KEY_NAME}_${KEY_TYPE}"
PUBLIC_KEY="${PRIVATE_KEY}.pub"

# Create .ssh directory if it doesn't exist
if [[ ! -d "$SSH_DIR" ]]; then
    log_info "Creating .ssh directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Check if keys already exist
if [[ -f "$PRIVATE_KEY" || -f "$PUBLIC_KEY" ]]; then
    log_warning "SSH keys already exist:"
    [[ -f "$PRIVATE_KEY" ]] && echo "  - $PRIVATE_KEY"
    [[ -f "$PUBLIC_KEY" ]] && echo "  - $PUBLIC_KEY"
    echo ""
    echo -n "Do you want to overwrite them? (y/N): "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Key generation cancelled"
        exit 0
    fi
    rm -f "$PRIVATE_KEY" "$PUBLIC_KEY"
fi

# Generate the key
log_info "Generating $KEY_TYPE SSH key pair..."
log_info "Key name: $KEY_NAME"
log_info "Location: $PRIVATE_KEY"

case "$KEY_TYPE" in
    "ed25519")
        ssh-keygen -t ed25519 -C "${KEY_NAME}-$(date +%Y%m%d)" -f "$PRIVATE_KEY" -N ""
        ;;
    "rsa")
        ssh-keygen -t rsa -b 4096 -C "${KEY_NAME}-$(date +%Y%m%d)" -f "$PRIVATE_KEY" -N ""
        ;;
esac

# Set proper permissions
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

log_success "SSH key pair generated successfully!"
echo ""
log_info "📁 Key Files:"
echo "  Private key: $PRIVATE_KEY"
echo "  Public key:  $PUBLIC_KEY"
echo ""

# Display public key
log_info "📋 Public Key (copy this to your server or Hetzner):"
echo "────────────────────────────────────────────────────"
cat "$PUBLIC_KEY"
echo "────────────────────────────────────────────────────"
echo ""

# Show how to use in Terraform
log_info "🔧 Using in Terraform Configuration:"
echo ""
echo "Add these to your terraform.tfvars file:"
echo ""
echo "ssh_public_key = <<-EOT"
cat "$PUBLIC_KEY"
echo "EOT"
echo ""
echo "ssh_private_key = <<-EOT"
cat "$PRIVATE_KEY"
echo "EOT"
echo ""

# Security reminder
log_warning "🔒 Security Reminders:"
echo "  ✓ Never commit private keys to version control"
echo "  ✓ Keep private keys secure (600 permissions)"
echo "  ✓ Use different keys for different environments"
echo "  ✓ Rotate keys regularly"
echo "  ✓ Add public key to your SSH agent: ssh-add $PRIVATE_KEY"
echo ""

log_info "💡 To test the key:"
echo "  ssh -i $PRIVATE_KEY root@YOUR_SERVER_IP"
echo ""

log_success "✨ Key generation complete!"
