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

  # Backend Configuration
  # 
  # Option 1: Local Backend (Default - Uncomment to use)
  # Stores state file locally. Simple but not suitable for team collaboration.
  #
  # backend "local" {
  #   path = "terraform.tfstate"
  # }

  # Option 2: Terraform Cloud (Uncomment and configure to use)
  # Provides remote state storage, locking, and team collaboration.
  # Requires: Terraform Cloud account at https://app.terraform.io
  #
  # cloud {
  #   organization = "YOUR_ORGANIZATION_NAME"
  #   workspaces {
  #     name = "YOUR_WORKSPACE_NAME"
  #   }
  # }

  # Option 3: S3 Backend (Uncomment and configure to use)
  # Stores state in AWS S3 with DynamoDB locking.
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = "eu-central-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
  
  # Note: Only ONE backend can be active at a time.
  # For local development, leave all backends commented (uses local backend by default).
  # For production, uncomment and configure your preferred backend.
}

# Configure Hetzner Cloud Provider
provider "hcloud" {
  token = var.hetzner_token
}

# Configure Hetzner DNS Provider
provider "hetznerdns" {
  apitoken = var.hetzner_dns_token
}
