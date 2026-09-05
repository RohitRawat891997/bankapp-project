#checkov:skip=CKV2_AWS_11: VPC Flow Logs not required for learning project

# ============================================
# Local Variables - Centralized Configuration
# ============================================
# These reduce duplication and make naming consistent across all resources

locals {
  service_name = "BankApp"
  common_tags = {
    Service     = local.service_name
    Environment = var.my_environment
    ManagedBy   = "Terraform"
  }

  # SSH and App access - from your laptop only
  my_ip_cidr = "103.181.90.188/32"
}

# ============================================
# SSH Key Pair
# ============================================
# Generates EC2 access using existing public key file
# This allows secure access to the EC2 instance via SSH

resource "aws_key_pair" "main" {
  key_name   = "terra-automate-key-${var.my_environment}"
  public_key = file("terra-automate-key.pub")

  tags = merge(local.common_tags, {
    Name = "terra-automate-key"
  })
}

# ============================================
# Default Security Group (Empty)
# ============================================
# Disable default inbound/outbound rules for security

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name = "${var.my_environment}-default-sg"
  }
}

# ============================================
# Security Group - For EC2 Instance
# ============================================
# Controls inbound/outbound traffic for EC2 instance
# Only allows SSH and app traffic from your laptop

resource "aws_security_group" "ec2" {
  name_prefix = "${var.my_environment}-ec2-"
  description = "Security group for ${local.service_name} EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.my_environment}-ec2-sg"
  })
}

# ============================================
# Ingress Rules (Inbound Traffic)
# ============================================

# Allow SSH access from your laptop only (port 22)
# Port 22 is the standard SSH port
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow SSH access from laptop"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = local.my_ip_cidr

  tags = {
    Name = "allow-ssh"
  }
}

# Allow HTTP traffic for BankApp application (port 8080)
# Port 8080 is commonly used for web applications
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTP access to ${local.service_name} application"

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
  cidr_ipv4   = local.my_ip_cidr

  tags = {
    Name = "allow-app-http"
  }
}

# ============================================
# Egress Rules (Outbound Traffic)
# ============================================

# Allow all outbound traffic
# Required for:
# - OS updates and patches
# - Package downloads
# - External API calls
# - Internet connectivity
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic for package downloads and updates"

  from_port   = 0
  to_port     = 65535
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "allow-all-outbound"
  }
}

# ============================================
# IAM Role for EC2 Instance
# ============================================
# Grants EC2 instance permissions to be managed by AWS Systems Manager
# This allows you to use AWS Session Manager for secure shell access
# without exposing SSH to the internet

resource "aws_iam_role" "ec2" {
  name_prefix = "${var.my_environment}-ec2-role-"
  description = "IAM role for ${local.service_name} EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# ============================================
# IAM Policy Attachment
# ============================================
# Attach AWS managed policy for Systems Manager access
# This policy provides permissions for Session Manager, CloudWatch, and basic EC2 operations

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================
# IAM Instance Profile
# ============================================
# Associates the IAM role with the EC2 instance
# This makes the role's permissions available to the EC2 instance

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.my_environment}-ec2-profile-"
  role        = aws_iam_role.ec2.name
}

# ============================================
# EC2 Instance - Main Application Server
# ============================================
# This is the core server that will run the BankApp application
# Configuration includes security hardening and monitoring best practices

resource "aws_instance" "main" {
  # -------- Basic Configuration --------
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  # -------- Network Configuration --------
  # Place instance in public subnet so it has public IP access
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # -------- IAM Configuration --------
  # Attach IAM role for Systems Manager access
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  # -------- User Data - Initialization Script --------
  # This script runs when the instance starts
  # Typically used for: system updates, package installation, app deployment
  user_data = file("script.sh")

  # -------- Security & Monitoring --------
  # Enable EBS optimization for better performance
  ebs_optimized = true

  # Enable detailed CloudWatch monitoring
  # (by default, basic monitoring is enabled)
  monitoring = true

  # -------- IMDSv2 Configuration --------
  # Enforces IMDSv2 for enhanced security
  # Prevents SSRF attacks that could compromise instance credentials
  metadata_options {
    http_tokens = "required"
  }

  # -------- Root Storage Configuration --------
  # Size: 30 GB should be sufficient for application and OS
  # Type: gp3 is faster and cheaper than gp2 for general purpose use
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false  # Note: Set to true for production environments
  }

  # -------- Tags --------
  # Tags help with resource organization and billing
  tags = merge(local.common_tags, {
    Name = "${var.my_environment}-bankapp-server"
  })

  # -------- Dependencies --------
  # Ensure key pair is created before EC2 instance
  depends_on = [aws_key_pair.main]
}

# ============================================
# Outputs - Useful Information
# ============================================
# These outputs provide important information after deployment
# Run: terraform output <output_name>

output "instance_id" {
  description = "EC2 Instance ID (use this for AWS CLI commands)"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "Private IP address of EC2 instance (internal to VPC)"
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of EC2 instance (access from internet)"
  value       = aws_instance.main.public_ip
}

output "security_group_id" {
  description = "Security Group ID (use for additional rules if needed)"
  value       = aws_security_group.ec2.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i terra-automate-key ec2-user@${aws_instance.main.public_ip}"
}

output "bankapp_url" {
  description = "URL to access BankApp application"
  value       = "http://${aws_instance.main.public_ip}:8080"
}
