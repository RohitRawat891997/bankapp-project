#!/bin/bash

# ============================================
# BankApp EC2 Instance Initialization Script
# ============================================
# This script runs when the EC2 instance starts
# It performs system setup, updates, and application preparation

set -e  # Exit if any command fails
set -x  # Print commands as they execute (useful for debugging)

# ============================================
# 1. System Updates
# ============================================
echo "Step 1: Updating system packages..."
yum update -y

# ============================================
# 2. Install Required Tools
# ============================================
echo "Step 2: Installing required software..."

# Install Java (commonly needed for banking applications)
yum install -y java-11-openjdk java-11-openjdk-devel

# Install Git (for version control)
yum install -y git

# Install Docker (optional - uncomment if using containers)
# yum install -y docker
# systemctl start docker
# systemctl enable docker

# ============================================
# 3. Create Application Directory
# ============================================
echo "Step 3: Setting up application directory..."
mkdir -p /opt/bankapp
cd /opt/bankapp

# ============================================
# 4. Application Startup (Example)
# ============================================
# TODO: Add your BankApp deployment steps here
# Examples:
# - Clone application from GitHub
# - Download WAR/JAR file from S3
# - Extract and configure application
# - Start the application service

echo "BankApp initialization complete!"
