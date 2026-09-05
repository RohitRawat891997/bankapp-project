# ============================================
# AWS Terraform Configuration
# ============================================
# This file contains the core Terraform settings

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment the following to use S3 backend for state management
  # This is important for team collaboration and production environments
  #
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "bankapp/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# ============================================
# AWS Provider Configuration
# ============================================
# Configures which AWS region to use for resources

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Terraform   = "true"
      Environment = var.my_environment
      Project     = "BankApp"
    }
  }
}
