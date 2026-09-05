#!/bin/bash

# ============================================
# Terraform Deployment Quick Start Script
# ============================================
# This script automates the deployment process
# Usage: bash deploy.sh [init|plan|apply|destroy|refresh]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ============================================
# Functions
# ============================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# ============================================
# Check Prerequisites
# ============================================

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    print_success "Terraform $(terraform version -json | grep terraform_version | head -1)"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI is not installed (optional but recommended)"
    else
        print_success "AWS CLI is installed"
    fi
    
    # Check SSH key
    if [ ! -f "terra-automate-key.pub" ]; then
        print_error "SSH public key (terra-automate-key.pub) not found!"
        print_warning "Generate with: ssh-keygen -t rsa -b 4096 -f terra-automate-key"
        exit 1
    fi
    print_success "SSH public key found"
    
    # Check private key
    if [ ! -f "terra-automate-key" ]; then
        print_warning "SSH private key (terra-automate-key) not found - you won't be able to SSH to the instance"
    else
        print_success "SSH private key found"
        chmod 600 terra-automate-key
    fi
}

# ============================================
# Initialize Terraform
# ============================================

terraform_init() {
    print_header "Initializing Terraform"
    terraform init
    print_success "Terraform initialized"
}

# ============================================
# Validate Configuration
# ============================================

terraform_validate() {
    print_header "Validating Terraform Configuration"
    if terraform validate; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
}

# ============================================
# Plan Deployment
# ============================================

terraform_plan() {
    print_header "Planning Terraform Deployment"
    terraform plan -out=tfplan
    print_success "Plan saved to tfplan"
    echo ""
    print_warning "Review the plan above carefully before applying"
}

# ============================================
# Apply Configuration
# ============================================

terraform_apply() {
    print_header "Applying Terraform Configuration"
    
    if [ ! -f "tfplan" ]; then
        print_warning "No tfplan file found, running plan first..."
        terraform_plan
    fi
    
    print_warning "This will create AWS resources and incur charges"
    read -p "Do you want to continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    terraform apply tfplan
    print_success "Terraform deployment completed!"
    
    # Display outputs
    echo ""
    print_header "Deployment Outputs"
    terraform output
}

# ============================================
# Destroy Infrastructure
# ============================================

terraform_destroy() {
    print_header "Destroying Terraform Infrastructure"
    
    print_error "WARNING: This will delete all AWS resources"
    read -p "Are you sure you want to destroy? Type 'destroy' to confirm: " confirm
    
    if [ "$confirm" != "destroy" ]; then
        print_warning "Destroy cancelled"
        exit 0
    fi
    
    terraform destroy
    print_success "Infrastructure destroyed"
}

# ============================================
# Refresh State
# ============================================

terraform_refresh() {
    print_header "Refreshing Terraform State"
    terraform refresh
    print_success "State refreshed"
}

# ============================================
# Display Outputs
# ============================================

terraform_output() {
    print_header "Terraform Outputs"
    terraform output
}

# ============================================
# Display Current Infrastructure
# ============================================

terraform_show() {
    print_header "Current Infrastructure"
    terraform show
}

# ============================================
# Main Script
# ============================================

main() {
    # Check if we're in the terraform directory
    if [ ! -f "terraform.tf" ]; then
        print_error "terraform.tf not found. Please run this script from the terraform directory"
        exit 1
    fi
    
    check_prerequisites
    terraform_validate
    
    # Get command argument
    COMMAND=${1:-"help"}
    
    case $COMMAND in
        init)
            terraform_init
            ;;
        plan)
            terraform_plan
            ;;
        apply)
            terraform_apply
            ;;
        destroy)
            terraform_destroy
            ;;
        refresh)
            terraform_refresh
            ;;
        output)
            terraform_output
            ;;
        show)
            terraform_show
            ;;
        full)
            terraform_init
            terraform_plan
            terraform_apply
            ;;
        *)
            echo "BankApp Terraform Deployment Script"
            echo ""
            echo "Usage: bash deploy.sh [command]"
            echo ""
            echo "Commands:"
            echo "  init      - Initialize Terraform (download plugins)"
            echo "  plan      - Plan the deployment (shows what will be created)"
            echo "  apply     - Apply the deployment (creates AWS resources)"
            echo "  destroy   - Destroy all resources"
            echo "  refresh   - Refresh Terraform state"
            echo "  output    - Display deployment outputs"
            echo "  show      - Display current infrastructure"
            echo "  full      - Run init, plan, and apply in sequence"
            echo ""
            echo "Example workflow:"
            echo "  bash deploy.sh init"
            echo "  bash deploy.sh plan"
            echo "  bash deploy.sh apply"
            echo ""
            exit 0
            ;;
    esac
}

main "$@"
