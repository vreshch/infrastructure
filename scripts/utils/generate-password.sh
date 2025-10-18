#!/bin/bash

# Password Hash Generation Utility
#
# This script generates bcrypt password hashes for Traefik basic authentication
# using htpasswd format.

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
    echo "   🔐 Password Hash Generation Utility"
    echo "=================================================="
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 [username]"
    echo ""
    echo "Arguments:"
    echo "  username   - Username for authentication (default: admin)"
    echo ""
    echo "Examples:"
    echo "  $0           # Generate hash for 'admin' user"
    echo "  $0 john      # Generate hash for 'john' user"
}

# Check if htpasswd is available
check_htpasswd() {
    if command -v htpasswd &> /dev/null; then
        return 0
    fi
    
    if command -v docker &> /dev/null; then
        log_warning "htpasswd not found locally, will use Docker"
        return 1
    fi
    
    log_error "Neither htpasswd nor Docker is available. Please install one of them:
    
    Ubuntu/Debian: sudo apt-get install apache2-utils
    RHEL/CentOS:   sudo yum install httpd-tools
    macOS:         brew install httpd (or use Docker)
    Docker:        docker run --rm httpd:alpine htpasswd -nbB user password"
}

generate_with_htpasswd() {
    local username="$1"
    local password="$2"
    htpasswd -nbB "$username" "$password" 2>/dev/null
}

generate_with_docker() {
    local username="$1"
    local password="$2"
    docker run --rm httpd:2.4-alpine htpasswd -nbB "$username" "$password" 2>/dev/null
}

show_banner

# Parse arguments
USERNAME="${1:-admin}"

log_info "Generating bcrypt password hash for user: $USERNAME"
echo ""

# Prompt for password
echo -ne "${YELLOW}Enter password: ${NC}"
read -rs PASSWORD
echo ""

if [[ -z "$PASSWORD" ]]; then
    log_error "Password cannot be empty"
fi

echo -ne "${YELLOW}Confirm password: ${NC}"
read -rs PASSWORD_CONFIRM
echo ""

if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
    log_error "Passwords do not match"
fi

echo ""
log_info "Generating hash..."

# Generate the hash
USE_DOCKER=false
if check_htpasswd; then
    HASH=$(generate_with_htpasswd "$USERNAME" "$PASSWORD")
else
    USE_DOCKER=true
    HASH=$(generate_with_docker "$USERNAME" "$PASSWORD")
fi

if [[ -z "$HASH" ]]; then
    log_error "Failed to generate password hash"
fi

log_success "Password hash generated successfully!"
echo ""

# Display the hash
log_info "📋 Complete htpasswd Entry:"
echo "────────────────────────────────────────────────────"
echo "$HASH"
echo "────────────────────────────────────────────────────"
echo ""

log_info "🔧 Using in Terraform Configuration:"
echo ""
echo "Add this to your terraform.tfvars file:"
echo ""
echo "admin_password_hash = \"$HASH\""
echo ""

# Show verification command
log_info "💡 To verify the hash works:"
if [[ "$USE_DOCKER" == "true" ]]; then
    echo "  docker run --rm httpd:2.4-alpine htpasswd -vbB /dev/stdin $USERNAME <<< \"$HASH\" <<< \"$PASSWORD\""
else
    echo "  echo '$HASH' | htpasswd -vbi /dev/stdin $USERNAME"
fi
echo ""

# Security reminder
log_warning "🔒 Security Reminders:"
echo "  ✓ Never commit passwords to version control"
echo "  ✓ Use different passwords for different environments"
echo "  ✓ Use strong passwords (12+ characters, mixed case, numbers, symbols)"
echo "  ✓ Consider using a password manager"
echo "  ✓ Rotate passwords regularly"
echo ""

# Password strength check
PASSWORD_LENGTH=${#PASSWORD}
if [[ $PASSWORD_LENGTH -lt 12 ]]; then
    log_warning "⚠️  Password is shorter than 12 characters. Consider using a longer password."
elif [[ $PASSWORD_LENGTH -lt 16 ]]; then
    log_info "✓ Password length is acceptable"
else
    log_success "✓ Password length is strong"
fi

log_success "✨ Hash generation complete!"
