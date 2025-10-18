#!/bin/bash

# Multi-Environment Deployment Script
# 
# This script manages Terraform deployments for multiple environments
# Supports both local state and Terraform Cloud backends
# 
# Usage:
#   ./scripts/deploy-env.sh dev     # Deploy to development environment
#   ./scripts/deploy-env.sh prod    # Deploy to production environment
#   ./scripts/deploy-env.sh dev destroy    # Destroy development environment
#   ./scripts/deploy-env.sh prod destroy   # Destroy production environment
#   ./scripts/deploy-env.sh dev plan --local  # Plan with local backend

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

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

show_usage() {
    echo "Usage: $0 <environment> [action] [options]"
    echo ""
    echo "Environments:"
    echo "  dev     - Development environment (dev.example.com)"
    echo "  prod    - Production environment (example.com)"
    echo ""
    echo "Actions:"
    echo "  plan     - Show deployment plan (default)"
    echo "  apply    - Deploy infrastructure"
    echo "  destroy  - Destroy infrastructure"
    echo "  output   - Show terraform outputs"
    echo "  validate - Validate configuration"
    echo ""
    echo "Options:"
    echo "  --local  - Use local backend (default: Terraform Cloud)"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 dev plan --local"
    echo "  $0 prod apply"
    echo "  $0 dev destroy --local"
}

# Validate arguments
if [[ $# -lt 1 ]]; then
    show_usage
    exit 1
fi

ENVIRONMENT="$1"
ACTION="${2:-plan}"
BACKEND="${3:-cloud}"

# Parse backend option
if [[ "$ACTION" == "--local" ]]; then
    BACKEND="local"
    ACTION="plan"
elif [[ "$BACKEND" == "--local" ]]; then
    BACKEND="local"
fi

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
    log_error "Invalid environment: $ENVIRONMENT. Use 'dev' or 'prod'"
fi

# Validate action
if [[ "$ACTION" != "plan" && "$ACTION" != "apply" && "$ACTION" != "destroy" && "$ACTION" != "output" && "$ACTION" != "validate" ]]; then
    log_error "Invalid action: $ACTION. Use 'plan', 'apply', 'destroy', 'output', or 'validate'"
fi

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "dev" ]]; then
    WORKSPACE_NAME="project-dev"
else
    WORKSPACE_NAME="project-prod"
fi
VAR_FILE="terraform.$ENVIRONMENT.tfvars"

log_info "🌍 Environment: $ENVIRONMENT"
log_info "🏗️  Workspace: $WORKSPACE_NAME"
log_info "�️  Backend: $BACKEND"
log_info "�📄 Variables: $VAR_FILE"
log_info "🎯 Action: $ACTION"

# Change to terraform directory
cd "$TERRAFORM_DIR" || log_error "Cannot change to terraform directory: $TERRAFORM_DIR"

# Check if var file exists
if [[ ! -f "$VAR_FILE" ]]; then
    log_error "Variable file not found: $VAR_FILE
    
Please create it first using:
  ./scripts/setup-env.sh $ENVIRONMENT"
fi

# Validate configuration if not just showing output
if [[ "$ACTION" != "output" ]]; then
    log_info "🔍 Validating configuration..."
    if [[ -x "$SCRIPT_DIR/utils/validate-config.sh" ]]; then
        if "$SCRIPT_DIR/utils/validate-config.sh" "$VAR_FILE"; then
            log_success "Configuration validation passed"
        else
            log_error "Configuration validation failed. Please fix the errors above."
        fi
    else
        log_warning "Validation script not found or not executable, skipping validation"
    fi
fi

# Initialize Terraform if needed
if [[ ! -d ".terraform" ]]; then
    log_info "🔧 Initializing Terraform..."
    terraform init
fi

# Configure backend based on selection
if [[ "$BACKEND" == "local" ]]; then
    log_info "⚙️  Using local backend..."
    
    # Create a backup of the original versions.tf
    cp versions.tf versions.tf.backup
    
    # Create versions.tf with local backend
    cat > versions.tf <<EOF
terraform {
  required_version = ">= 1.12"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "~> 2.2"
    }
  }
  
  # Local backend - state stored in local file
  backend "local" {
    path = "terraform-$ENVIRONMENT.tfstate"
  }
}

# Configure Hetzner provider
provider "hcloud" {
  token = var.hetzner_token
}

# Configure DNS provider
provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}
EOF
    
    # Re-initialize with local backend
    log_info "🔄 Re-initializing with local backend..."
    terraform init -reconfigure
    
else
    # Terraform Cloud backend
    log_info "⚙️  Configuring Terraform Cloud workspace..."
    
    # Create a backup of the original versions.tf
    cp versions.tf versions.tf.backup
    
    # Create versions.tf with cloud backend
    cat > versions.tf <<EOF
terraform {
  required_version = ">= 1.12"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "~> 2.2"
    }
  }

  cloud {
    organization = "YOUR_ORGANIZATION"
    workspaces {
      name = "$WORKSPACE_NAME"
    }
  }
}

# Configure Hetzner provider
provider "hcloud" {
  token = var.hetzner_token
}

# Configure DNS provider
provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}
EOF
    
    # Re-initialize with cloud backend
    log_info "🔄 Re-initializing with workspace: $WORKSPACE_NAME"
    terraform init
fi

# Execute the requested action
case "$ACTION" in
    "validate")
        log_info "🔍 Validating Terraform configuration..."
        terraform validate
        log_success "Terraform configuration is valid"
        ;;
    
    "plan")
        log_info "📋 Running Terraform plan for $ENVIRONMENT environment..."
        terraform plan -var-file="$VAR_FILE"
        ;;
    
    "apply")
        log_warning "🚀 This will deploy infrastructure to $ENVIRONMENT environment"
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            log_warning "⚠️  WARNING: This is PRODUCTION deployment!"
            echo -n "Are you sure you want to continue? (yes/no): "
            read -r confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "Deployment cancelled"
                exit 0
            fi
        fi
        
        log_info "🚀 Applying Terraform configuration..."
        terraform apply -var-file="$VAR_FILE"
        
        if [[ $? -eq 0 ]]; then
            log_success "🎉 Infrastructure deployed successfully!"
            log_info "📊 Getting deployment outputs..."
            terraform output
        else
            log_error "Deployment failed!"
        fi
        ;;
    
    "destroy")
        log_warning "🔥 This will DESTROY all infrastructure in $ENVIRONMENT environment"
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            log_warning "⚠️  WARNING: This will DESTROY PRODUCTION infrastructure!"
        fi
        echo -n "Type 'destroy' to confirm: "
        read -r confirm
        if [[ "$confirm" != "destroy" ]]; then
            log_info "Destruction cancelled"
            exit 0
        fi
        
        log_info "🔥 Destroying infrastructure..."
        terraform destroy -var-file="$VAR_FILE"
        ;;
    
    "output")
        log_info "📊 Terraform outputs for $ENVIRONMENT environment:"
        terraform output
        ;;
esac

# Restore original versions.tf
if [[ -f "versions.tf.backup" ]]; then
    mv versions.tf.backup versions.tf
    log_info "Restored original versions.tf"
fi

# Clean up temporary files
rm -f backend-config.tmp

log_success "✨ Operation completed for $ENVIRONMENT environment"

# Show quick access information
if [[ "$ACTION" == "apply" ]]; then
    echo ""
    log_info "🌐 Quick Access URLs:"
    if [[ "$ENVIRONMENT" == "dev" ]]; then
        echo "   • Development Site: https://dev.example.com"
        echo "   • Admin Dashboard: https://admin.dev.example.com"
        echo "   • Swarmpit: https://swarmpit.dev.example.com"
        echo "   • Logs: https://logs.dev.example.com"
    else
        echo "   • Production Site: https://example.com"
        echo "   • Admin Dashboard: https://admin.example.com"
        echo "   • Swarmpit: https://swarmpit.example.com"
        echo "   • Logs: https://logs.example.com"
    fi
    
    echo ""
    log_info "📡 SSH Access:"
    terraform output ssh_connection_string 2>/dev/null || echo "   Run: terraform output ssh_connection_string"
fi
