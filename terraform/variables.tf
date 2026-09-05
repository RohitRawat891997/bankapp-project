# ============================================
# Terraform Variables - Input Configuration
# ============================================
# Define all variables used across your Terraform configuration
# These can be overridden via CLI, environment variables, or terraform.tfvars file

# ============================================
# AWS Region
# ============================================
# The AWS region where all resources will be created

variable "aws_region" {
  description = "AWS region for resource provisioning (e.g., us-east-1, eu-west-1)"
  type        = string
  default     = "us-east-1"
}

# ============================================
# EC2 AMI ID
# ============================================
# Amazon Machine Image ID - defines the OS and base software
# Default: Amazon Linux 2 (free tier eligible)
# You can change this to Ubuntu, RHEL, or other supported AMIs

variable "ami_id" {
  description = "AMI ID for EC2 instance (Amazon Linux 2 by default)"
  type        = string
  default     = "ami-0f8a61b66d1accaee"

  validation {
    condition     = can(regex("^ami-[0-9a-f]{17}$", var.ami_id))
    error_message = "AMI ID must be valid (format: ami-xxxxxxxxxxxxxxxx)."
  }
}

# ============================================
# EC2 Instance Type
# ============================================
# Determines the computing power and memory of your instance
# t2/t3 = burstable instances (good for development/testing)
# Larger types available: m5.large, c5.large (for production)

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free tier, t2.small/medium for more power)"
  type        = string
  default     = "t2.micro"

  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium",
      "m5.large", "m6i.large",
      "c5.large", "c6i.large"
    ], var.instance_type)

    error_message = "Instance type must be one of: t2.micro, t2.small, t2.medium, t3.micro, t3.small, t3.medium, m5.large, m6i.large, c5.large, c6i.large"
  }
}

# ============================================
# Deployment Environment
# ============================================
# Used for naming resources and applying environment-specific settings
# Example: dev-bankapp-server, staging-bankapp-server, prd-bankapp-server

variable "my_environment" {
  description = "Deployment environment name (dev, staging, prd)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prd"], var.my_environment)
    error_message = "Environment must be one of: dev, staging, prd"
  }
}
