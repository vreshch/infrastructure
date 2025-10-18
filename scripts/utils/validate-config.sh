#!/bin/bash

# Configuration Validation Utility
#
# This script validates Terraform configuration files before deployment
# to catch common errors and missing required values.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

log_check() {
    echo -e "${GREEN}✓${NC} $1"
}

show_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "   🔍 Configuration Validation Utility"
    echo "=================================================="
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 <config-file>"
    echo ""
    echo "Arguments:"
    echo "  config-file   - Path to terraform.tfvars file to validate"
    echo ""
    echo "Examples:"
    echo "  $0 ../terraform/terraform.dev.tfvars"
    echo "  $0 terraform.prod.tfvars"
}

validate_required_field() {
    local file="$1"
    local field="$2"
    local description="$3"
    
    if grep -q "^${field} = \"YOUR_" "$file" || grep -q "^#.*${field}" "$file" || ! grep -q "^${field}" "$file"; then
        log_error "$description ($field) is not configured"
        return 1
    else
        log_check "$description is configured"
        return 0
    fi
}

validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-z0-9.-]+\.[a-z]{2,}$ ]]; then
        log_error "Invalid domain format: $domain"
        return 1
    fi
    log_check "Domain format is valid"
    return 0
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi
    log_check "Email format is valid"
    return 0
}

validate_ssh_key() {
    local key="$1"
    local key_type="$2"
    
    if [[ "$key" == "YOUR_"* ]] || [[ -z "$key" ]]; then
        log_error "$key_type is not configured"
        return 1
    fi
    
    if [[ "$key_type" == "Public Key" ]]; then
        if [[ ! "$key" =~ ^ssh- ]]; then
            log_error "$key_type does not start with 'ssh-'"
            return 1
        fi
    elif [[ "$key_type" == "Private Key" ]]; then
        if [[ ! "$key" =~ "BEGIN" ]] || [[ ! "$key" =~ "PRIVATE KEY" ]]; then
            log_error "$key_type is not in PEM format"
            return 1
        fi
    fi
    
    log_check "$key_type format is valid"
    return 0
}

show_banner

# Check arguments
if [[ $# -ne 1 ]]; then
    show_usage
    exit 1
fi

CONFIG_FILE="$1"

# Check if file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    log_error "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

log_info "Validating configuration: $CONFIG_FILE"
echo ""

# Read the configuration file
CONFIG_CONTENT=$(cat "$CONFIG_FILE")

# ============================================================================
# SECTION 1: Required Credentials
# ============================================================================
echo -e "${BLUE}━━━ Hetzner Credentials ━━━${NC}"

if validate_required_field "$CONFIG_FILE" "hetzner_token" "Hetzner Cloud API token"; then
    TOKEN=$(grep "^hetzner_token" "$CONFIG_FILE" | cut -d'"' -f2)
    if [[ ${#TOKEN} -lt 64 ]]; then
        log_warning "Hetzner token seems short (expected 64 characters)"
    fi
fi

validate_required_field "$CONFIG_FILE" "hetzner_dns_token" "Hetzner DNS API token"
validate_required_field "$CONFIG_FILE" "hetzner_dns_zone_id" "Hetzner DNS Zone ID"

echo ""

# ============================================================================
# SECTION 2: Domain Configuration
# ============================================================================
echo -e "${BLUE}━━━ Domain Configuration ━━━${NC}"

if validate_required_field "$CONFIG_FILE" "domain_name" "Domain name"; then
    DOMAIN=$(grep "^domain_name" "$CONFIG_FILE" | cut -d'"' -f2)
    validate_domain "$DOMAIN"
fi

validate_required_field "$CONFIG_FILE" "traefik_host" "Traefik dashboard hostname"
validate_required_field "$CONFIG_FILE" "swarmpit_host" "Swarmpit management hostname"
validate_required_field "$CONFIG_FILE" "dozzle_host" "Dozzle logs hostname"

if validate_required_field "$CONFIG_FILE" "traefik_acme_email" "Let's Encrypt email"; then
    EMAIL=$(grep "^traefik_acme_email" "$CONFIG_FILE" | cut -d'"' -f2)
    validate_email "$EMAIL"
fi

echo ""

# ============================================================================
# SECTION 3: Server Configuration
# ============================================================================
echo -e "${BLUE}━━━ Server Configuration ━━━${NC}"

validate_required_field "$CONFIG_FILE" "server_name" "Server name"

if validate_required_field "$CONFIG_FILE" "server_type" "Server type"; then
    SERVER_TYPE=$(grep "^server_type" "$CONFIG_FILE" | cut -d'"' -f2)
    VALID_TYPES=("cx11" "cx21" "cx22" "cx31" "cx32" "cx41" "cx42" "cx51" "cx52")
    if [[ ! " ${VALID_TYPES[@]} " =~ " ${SERVER_TYPE} " ]]; then
        log_error "Invalid server type: $SERVER_TYPE"
    else
        log_check "Server type is valid"
    fi
fi

if validate_required_field "$CONFIG_FILE" "location" "Datacenter location"; then
    LOCATION=$(grep "^location" "$CONFIG_FILE" | cut -d'"' -f2)
    VALID_LOCATIONS=("nbg1" "fsn1" "hel1" "ash" "hil")
    if [[ ! " ${VALID_LOCATIONS[@]} " =~ " ${LOCATION} " ]]; then
        log_error "Invalid location: $LOCATION"
    else
        log_check "Datacenter location is valid"
    fi
fi

echo ""

# ============================================================================
# SECTION 4: SSH Configuration
# ============================================================================
echo -e "${BLUE}━━━ SSH Configuration ━━━${NC}"

# Extract SSH keys (they are multi-line in heredoc format)
if grep -q "^ssh_public_key = <<-EOT" "$CONFIG_FILE"; then
    SSH_PUBLIC=$(sed -n '/^ssh_public_key = <<-EOT/,/^EOT/p' "$CONFIG_FILE" | sed '1d;$d')
    validate_ssh_key "$SSH_PUBLIC" "Public Key"
else
    log_error "SSH public key is not configured"
fi

if grep -q "^ssh_private_key = <<-EOT" "$CONFIG_FILE"; then
    SSH_PRIVATE=$(sed -n '/^ssh_private_key = <<-EOT/,/^EOT/p' "$CONFIG_FILE" | sed '1d;$d')
    validate_ssh_key "$SSH_PRIVATE" "Private Key"
else
    log_error "SSH private key is not configured"
fi

echo ""

# ============================================================================
# SECTION 5: Authentication
# ============================================================================
echo -e "${BLUE}━━━ Authentication ━━━${NC}"

if validate_required_field "$CONFIG_FILE" "admin_password_hash" "Admin password hash"; then
    HASH=$(grep "^admin_password_hash" "$CONFIG_FILE" | cut -d'"' -f2)
    if [[ ! "$HASH" =~ \$2[ayb]\$ ]]; then
        log_error "Admin password hash is not in bcrypt format"
    else
        log_check "Admin password hash format is valid"
    fi
fi

echo ""

# ============================================================================
# SECTION 6: Optional Warnings
# ============================================================================
echo -e "${BLUE}━━━ Additional Checks ━━━${NC}"

# Check file permissions
FILE_PERMS=$(stat -c %a "$CONFIG_FILE" 2>/dev/null || stat -f %A "$CONFIG_FILE" 2>/dev/null)
if [[ "$FILE_PERMS" != "600" ]]; then
    log_warning "File permissions are $FILE_PERMS (recommended: 600 for security)"
    echo "  Fix with: chmod 600 $CONFIG_FILE"
else
    log_check "File permissions are secure (600)"
fi

# Check for sensitive data in comments
if grep -q "password" "$CONFIG_FILE" | grep -v "password_hash"; then
    log_warning "File contains 'password' in plain text (check comments)"
fi

# Environment-specific checks
if [[ "$CONFIG_FILE" =~ prod ]]; then
    log_info "Production environment detected - additional checks:"
    
    if grep -q "example.com" "$CONFIG_FILE"; then
        log_warning "Configuration contains example.com - update with real domain"
    fi
    
    if grep -q "server_type = \"cx11\"" "$CONFIG_FILE" || grep -q "server_type = \"cx21\"" "$CONFIG_FILE"; then
        log_warning "Small server type for production (consider cx31 or larger)"
    fi
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    log_success "✨ Configuration is valid! No errors or warnings found."
    echo ""
    log_info "🚀 Ready to deploy with:"
    echo "  terraform plan -var-file=\"$CONFIG_FILE\""
    echo "  terraform apply -var-file=\"$CONFIG_FILE\""
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    log_warning "⚠️  Configuration has $WARNINGS warning(s) but no critical errors."
    echo ""
    log_info "You can proceed with deployment, but review the warnings above."
    exit 0
else
    log_error "❌ Configuration has $ERRORS error(s) and $WARNINGS warning(s)."
    echo ""
    log_info "Please fix the errors above before deploying."
    exit 1
fi
