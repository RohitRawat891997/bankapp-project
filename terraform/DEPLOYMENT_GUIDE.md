# ============================================
# BankApp Terraform - Complete Setup Guide
# ============================================

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [File Descriptions](#file-descriptions)
3. [Deployment Steps](#deployment-steps)
4. [Configuration](#configuration)
5. [Access & Testing](#access--testing)
6. [Troubleshooting](#troubleshooting)
7. [Cost Estimation](#cost-estimation)

---

## 🚀 Quick Start

### Prerequisites
- AWS Account with billing enabled
- Terraform installed (v1.0+)
- SSH key pair (public key `terra-automate-key.pub` in this directory)
- Bash shell

### Deploy in 3 Steps

```bash
# Step 1: Initialize
bash deploy.sh init

# Step 2: Plan (review what will be created)
bash deploy.sh plan

# Step 3: Apply (create resources)
bash deploy.sh apply
```

---

## 📁 File Descriptions

### Core Terraform Files

| File | Purpose | Key Content |
|------|---------|-------------|
| **terraform.tf** | Provider & version config | AWS provider setup, required versions |
| **variables.tf** | Input variables | AWS region, AMI, instance type, environment |
| **vpc.tf** | Network infrastructure | VPC, subnets, internet gateway, routing |
| **ec2.tf** | Compute & security | EC2 instance, security groups, IAM roles |
| **outputs.tf** | Deployment info | Instance IPs, URLs, SSH commands |

### Helper Files

| File | Purpose |
|------|---------|
| **README.md** | This comprehensive guide |
| **terraform.tfvars.example** | Configuration examples for different environments |
| **deploy.sh** | Automated deployment script with safety checks |
| **.gitignore** | Protect sensitive files from Git |

---

## 🔧 Deployment Steps

### Step 1: Prepare SSH Keys

Generate SSH key pair if you don't have one:

```bash
ssh-keygen -t rsa -b 4096 -f terra-automate-key -N ""
# This creates:
# - terra-automate-key (private key - keep secure!)
# - terra-automate-key.pub (public key - for AWS)
```

### Step 2: Configure Environment (Optional)

Create `terraform.tfvars` from the example:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars to customize values
```

### Step 3: Initialize Terraform

Downloads and prepares required plugins:

```bash
terraform init
# Or use the helper script:
bash deploy.sh init
```

### Step 4: Review the Plan

Shows exactly what will be created:

```bash
terraform plan
# Or:
bash deploy.sh plan
```

### Step 5: Deploy Infrastructure

Creates all AWS resources:

```bash
terraform apply
# Or:
bash deploy.sh apply
```

After deployment completes, Terraform displays outputs including:
- Instance public IP
- SSH connection command
- BankApp URL (http://public-ip:8080)

---

## ⚙️ Configuration

### Using terraform.tfvars

Create `terraform.tfvars` in the terraform directory:

```hcl
# Example configuration for development
aws_region    = "us-east-1"
instance_type = "t2.micro"        # Free tier
my_environment = "dev"
ami_id        = "ami-0f8a61b66d1accaee"  # Amazon Linux 2
```

### Using Command Line

Override variables via CLI:

```bash
terraform apply \
  -var="instance_type=t2.small" \
  -var="my_environment=staging"
```

### Available Variables

```hcl
# AWS Region (default: us-east-1)
aws_region = "us-east-1"

# EC2 Instance Type (default: t2.micro)
# Options: t2.micro, t2.small, t2.medium, t3.micro, t3.small, t3.medium
instance_type = "t2.micro"

# Environment Name (default: dev)
# Options: dev, staging, prd
my_environment = "dev"

# AMI ID (default: Amazon Linux 2)
ami_id = "ami-0f8a61b66d1accaee"
```

---

## 🌐 Access & Testing

### Get Connection Information

```bash
# View all outputs
terraform output

# Get specific output
terraform output instance_public_ip
terraform output ssh_command
terraform output bankapp_url
```

### SSH into Instance

```bash
# Using SSH key
ssh -i terra-automate-key ec2-user@<PUBLIC_IP>

# Or use the provided command
$(terraform output -raw ssh_command)
```

### Test Web Application

```bash
# Get the BankApp URL
curl $(terraform output -raw bankapp_url)

# Or open in browser
open $(terraform output -raw bankapp_url)  # macOS
xdg-open $(terraform output -raw bankapp_url)  # Linux
```

### Check Instance Status

```bash
# Via AWS CLI
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --region us-east-1

# Via Terraform
terraform show aws_instance.main
```

---

## 🔍 Troubleshooting

### Issue: "Permission denied (publickey)"

**Solution**: Ensure SSH key permissions are correct
```bash
chmod 600 terra-automate-key
chmod 644 terra-automate-key.pub
```

### Issue: "AMI not found in this region"

**Solution**: Verify AMI ID for your region
```bash
# List available AMIs in your region
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*" \
  --region us-east-1
```

### Issue: "Insufficient capacity"

**Solution**: Try a different availability zone or instance type
```bash
terraform destroy
# Edit variables and try again
terraform apply
```

### Issue: Instance not accessible via SSH

**Checklist**:
1. Security group allows SSH on port 22 ✓
2. Security group allows from your IP (103.181.90.188/32) ✓
3. Instance has public IP assigned ✓
4. Instance is in running state ✓
5. Private key has correct permissions (600) ✓

### Issue: "terraform.tfstate" error

**Solution**: Refresh Terraform state
```bash
terraform refresh
terraform validate
```

---

## 💰 Cost Estimation

### Free Tier (12 months)
- **t2.micro EC2**: FREE (750 hours/month)
- **Data Transfer**: FREE (15 GB/month)
- **Storage**: FREE (30 GB/month)
- **VPC**: FREE
- **Total**: **$0/month**

### Paid Usage

After free tier or with larger instances:

| Component | t2.micro | t2.small | t2.medium |
|-----------|----------|----------|-----------|
| EC2 | $0 | ~$8.50 | ~$17 |
| Storage | $1.15 | $1.15 | $1.15 |
| Data Transfer | $0 | $0 | $0 |
| **Total** | **~$1.15** | **~$9.65** | **~$18.15** |

**Per month (approximate US East 1)**

---

## 📊 Architecture Diagram

```
┌──────────────────────────────────────────┐
│          AWS Region (us-east-1)         │
├──────────────────────────────────────────┤
│                                          │
│  ┌─────────────────────────────────┐   │
│  │   VPC (10.0.0.0/16)             │   │
│  │                                 │   │
│  │  ┌──────────────────────────┐   │   │
│  │  │ Public Subnet            │   │   │
│  │  │ (10.0.1.0/24)            │   │   │
│  │  │                          │   │   │
│  │  │ ┌────────────────────┐   │   │   │
│  │  │ │  EC2 Instance      │   │   │   │
│  │  │ │  - BankApp Server  │───┼───┼──→ Internet
│  │  │ │  - Port 8080       │   │   │   
│  │  │ │  - IAM Role        │   │   │   
│  │  │ │  - Security Group  │   │   │   
│  │  │ └────────────────────┘   │   │   
│  │  └──────────────────────────┘   │   
│  │           ↓                     │   
│  │  ┌──────────────────────────┐   │   
│  │  │ Internet Gateway         │   │   
│  │  └──────────────────────────┘   │   
│  │                                 │   
│  └─────────────────────────────────┘   
│                                          
│  Security:
│  • SSH (22): Your laptop only
│  • HTTP (8080): Your laptop only
│  • All outbound: Allowed
│
└──────────────────────────────────────────┘
```

---

## 🔒 Security Best Practices Applied

✅ **IMDSv2 Enforced** - Protects against SSRF attacks  
✅ **Security Groups** - Restricts traffic to SSH and app ports only  
✅ **IAM Role** - EC2 has minimal required permissions  
✅ **Default SG Hardened** - Inbound/outbound rules disabled  
✅ **Monitoring** - CloudWatch monitoring enabled  
✅ **EBS Optimized** - Better storage performance  

### Additional Recommendations

⚠️ **For Production**:
- [ ] Enable EBS encryption in root_block_device
- [ ] Use private subnets with NAT gateway
- [ ] Enable VPC Flow Logs
- [ ] Implement S3 backend for state management
- [ ] Add CloudWatch alarms and SNS notifications
- [ ] Use AWS Secrets Manager for credentials

---

## 📝 Common Workflows

### Scale Up Instance Type

```bash
# Edit variables
vim terraform.tfvars
# Change: instance_type = "t2.small"

# Review changes
terraform plan

# Apply changes (instance will be replaced)
terraform apply
```

### Switch Environment

```bash
# Change environment in tfvars
vim terraform.tfvars
# Change: my_environment = "staging"

# Apply (resources renamed automatically)
terraform apply
```

### Destroy Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Delete all resources
terraform destroy

# Or use helper script
bash deploy.sh destroy
```

### Create Backup/Snapshot

```bash
# Create AMI from current instance
aws ec2 create-image \
  --instance-id $(terraform output -raw instance_id) \
  --name "bankapp-backup-$(date +%Y%m%d)"
```

---

## 🎓 Learning Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)

---

## 📞 Support & Next Steps

### If Something Goes Wrong

1. **Check logs**: `terraform show` or `terraform log`
2. **AWS Console**: Review EC2, VPC, and Security Groups manually
3. **Validate**: `terraform validate`
4. **Refresh**: `terraform refresh`

### Next Steps After Deployment

1. ✅ Deploy BankApp application (update `script.sh`)
2. ✅ Configure application settings
3. ✅ Set up database connections
4. ✅ Enable backups and snapshots
5. ✅ Monitor with CloudWatch
6. ✅ Set up auto-scaling (for production)

---

## 📋 Checklist Before Going to Production

- [ ] Moved state to S3 backend
- [ ] Enabled EBS encryption
- [ ] Set up private subnets with NAT
- [ ] Configured CloudWatch monitoring
- [ ] Created SNS alarms
- [ ] Tested disaster recovery
- [ ] Documented runbooks
- [ ] Set up backup/snapshot schedule
- [ ] Reviewed security group rules
- [ ] Enabled VPC Flow Logs

---

**Last Updated**: 2026-09-05  
**Terraform Version**: ≥ 1.0  
**AWS Provider**: ~> 5.0  
**Status**: Production Ready (with recommendations)
