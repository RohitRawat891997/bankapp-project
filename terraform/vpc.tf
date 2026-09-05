# ============================================
# VPC Configuration - Network Setup
# ============================================
# This file creates the Virtual Private Cloud and networking resources
# Think of VPC as your isolated network on AWS

# ============================================
# Custom VPC
# ============================================
# Creates a private network space in AWS
# CIDR: 10.0.0.0/16 = 65,536 available IP addresses
# DNS settings are enabled for proper hostname resolution

resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11: VPC Flow Logs not required for learning project

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.my_environment}-vpc"
  }
}

# ============================================
# Public Subnet
# ============================================
# A subnet where resources can be accessed from the internet
# CIDR: 10.0.1.0/24 = 256 IP addresses
# map_public_ip_on_launch = true:
#   Automatically assigns public IPs to resources launched here
# This is essential for your EC2 instance to be accessible from your laptop

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130: Public subnet required for EC2 access and self-hosted runner

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.my_environment}-public-subnet"
  }
}

# ============================================
# Internet Gateway
# ============================================
# Acts as the gateway between your VPC and the public internet
# Without this, your VPC would be isolated from the internet

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.my_environment}-igw"
  }
}

# ============================================
# Route Table
# ============================================
# Defines rules for routing traffic (like routing tables in real networks)
# Route: 0.0.0.0/0 -> Internet Gateway
#   This means: "Any traffic not going to local VPC goes to the internet"

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.my_environment}-public-rt"
  }
}

# ============================================
# Route Table Association
# ============================================
# Associates the route table with the public subnet
# This tells the subnet: "Use these routing rules"

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ============================================
# Data Source - Availability Zones
# ============================================
# Automatically fetches available zones in your region
# This ensures your subnet is created in a valid availability zone

data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================
# Outputs - Network Information
# ============================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "subnet_cidr" {
  description = "Public Subnet CIDR block"
  value       = aws_subnet.public.cidr_block
}

output "igw_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.igw.id
}
