# ============================================
# BankApp Terraform - Quick Reference Guide
# ============================================

## 📂 Directory Structure

```
terraform/
├── README.md                    # Main documentation
├── DEPLOYMENT_GUIDE.md          # Complete deployment guide
├── terraform.tf                 # Terraform configuration
├── variables.tf                 # Input variables
├── vpc.tf                       # Network setup
├── ec2.tf                       # Server & security
├── outputs.tf                   # Deployment outputs
├── script.sh                    # EC2 initialization
├── deploy.sh                    # Deployment automation
├── terraform.tfvars.example     # Configuration template
├── .gitignore                   # Git ignore rules
└── QUICK_REFERENCE.md           # This file
```

---

## 🚀 5-Minute Deployment

### 1. Prerequisites
```bash
# Install Terraform
brew install terraform  # macOS
sudo apt-get install terraform  # Linux
choco install terraform  # Windows

# Check AWS credentials
aws configure
```

### 2. Generate SSH Keys
```bash
cd terraform
ssh-keygen -t rsa -b 4096 -f terra-automate-key -N ""
```

### 3. Deploy
```bash
# Option A: Using script (recommended)
bash deploy.sh init
bash deploy.sh plan
bash deploy.sh apply

# Option B: Using Terraform directly
terraform init
terraform plan
terraform apply
```

### 4. Access Your Server
```bash
# Get connection details
terraform output ssh_command
terraform output bankapp_url

# Connect via SSH
ssh -i terra-automate-key ec2-user@<PUBLIC_IP>
```

---

## ⚙️ Common Commands

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# View outputs
terraform output
terraform output instance_public_ip
terraform output ssh_command

# Refresh state
terraform refresh

# Destroy resources
terraform destroy

# Debug mode
TF_LOG=DEBUG terraform apply
```

---

## 🔧 Configuration

### Edit Variables
```bash
# Copy example
cp terraform.tfvars.example terraform.tfvars

# Edit
vim terraform.tfvars
```

### Available Options
```hcl
aws_region    = "us-east-1"           # AWS region
instance_type = "t2.micro"            # t2.micro, t2.small, t2.medium
my_environment = "dev"                # dev, staging, prd
ami_id        = "ami-0f8a61b66d1accaee"  # Amazon Linux 2
```

---

## 🔍 Troubleshooting

| Problem | Solution |
|---------|----------|
| SSH permission denied | `chmod 600 terra-automate-key` |
| AMI not found | Update `ami_id` for your region |
| Instance unreachable | Check security group allows your IP |
| State locked | `terraform force-unlock <LOCK_ID>` |
| Want to rebuild | `terraform destroy && terraform apply` |

---

## 📊 Resource Summary

| Resource | Name | Details |
|----------|------|---------|
| VPC | `{env}-vpc` | 10.0.0.0/16 |
| Subnet | `{env}-public-subnet` | 10.0.1.0/24 |
| Security Group | `{env}-ec2-sg` | SSH (22), HTTP (8080) |
| EC2 Instance | `{env}-bankapp-server` | Configurable size |
| IAM Role | `{env}-ec2-role-*` | SSM access |
| Key Pair | `terra-automate-key-{env}` | SSH access |

---

## 💾 State Management

### Local State (Development)
```bash
# State file stored locally
# ⚠️ Not ideal for teams
cat terraform.tfstate  # Contains sensitive data!
```

### Remote State (Production)
```bash
# Use S3 backend for team collaboration
# Uncomment in terraform.tf and configure:
backend "s3" {
  bucket = "your-bucket"
  key    = "bankapp/terraform.tfstate"
  region = "us-east-1"
}
```

---

## 🔐 Security Checklist

- ✅ SSH key protected (600 permissions)
- ✅ terraform.tfstate in .gitignore
- ✅ IMDSv2 enforced
- ✅ Security groups restrict access
- ✅ IAM role with least privileges
- ✅ EBS encryption (optional in dev, required in prod)

---

## 💰 Cost Tracker

### Free Tier (First 12 months)
- **t2.micro EC2**: FREE (750 hrs/month)
- **30GB Storage**: FREE
- **Data Transfer**: FREE (15GB/month)
- **Total**: **$0**

### After Free Tier
- **t2.micro**: ~$9/month
- **t2.small**: ~$18/month  
- **t3.medium**: ~$31/month

---

## 📞 Quick Help

```bash
# Show all outputs
terraform output

# Show specific output
terraform output instance_public_ip

# Show infrastructure
terraform show

# Show plan without applying
terraform plan

# Get help on a resource
terraform show -help
```

---

## 🎯 Next Steps

1. **Deploy**: Run the 5-minute deployment above
2. **Update script.sh**: Add BankApp deployment commands
3. **Monitor**: Set up CloudWatch alarms
4. **Backup**: Enable snapshots
5. **Scale**: Adjust instance type as needed
6. **Secure**: Move state to S3 for production

---

## 📚 Documentation

- **README.md** - Comprehensive overview
- **DEPLOYMENT_GUIDE.md** - Detailed setup guide
- **terraform.tfvars.example** - Configuration templates
- **[Terraform Docs](https://www.terraform.io/docs)** - Official reference
- **[AWS Docs](https://docs.aws.amazon.com)** - AWS resources

---

## ⏱️ Typical Timeline

| Step | Time | What Happens |
|------|------|--------------|
| Initialize | 1-2 min | Downloads plugins |
| Plan | 1-2 min | Shows what will be created |
| Apply | 3-5 min | Creates EC2, VPC, networking |
| SSH Access | Immediate | Instance ready to use |

---

## 🚨 Emergency Commands

```bash
# Immediately stop all resources
terraform destroy

# Force unlock state
terraform force-unlock

# Clean up everything locally
rm -rf .terraform terraform.tfstate*
```

---

**Created**: 2026-09-05  
**Version**: 1.0  
**Status**: Ready to Deploy  
**Questions?** See DEPLOYMENT_GUIDE.md or README.md
