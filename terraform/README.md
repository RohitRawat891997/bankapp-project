# ============================================
# BankApp Terraform Deployment README
# ============================================

## Overview
This Terraform configuration deploys a complete AWS infrastructure for the BankApp application with:
- **EC2 Instance** - Main application server
- **VPC** - Isolated network environment
- **Public Subnet** - For internet-facing resources
- **Security Groups** - Network access controls
- **IAM Role** - EC2 instance permissions
- **Key Pair** - SSH access management

---

## Quick Start Guide

### Prerequisites
1. **AWS Account** with appropriate permissions
2. **Terraform** installed (v1.0 or higher)
3. **AWS CLI** configured with credentials
4. **SSH Key** (`terra-automate-key.pub`) in the terraform directory

### Deployment Steps

#### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```
This downloads required Terraform plugins and prepares the working directory.

#### Step 2: Validate Configuration
```bash
terraform validate
```
Checks syntax and configuration validity.

#### Step 3: Plan Deployment
```bash
terraform plan
```
Shows what resources will be created. Review output carefully.

#### Step 4: Apply Configuration
```bash
terraform apply
```
Creates all AWS resources. Type `yes` to confirm.

#### Step 5: Access Your Instance
After deployment completes, Terraform outputs the public IP address:
```bash
ssh -i terra-automate-key ec2-user@<PUBLIC_IP>
```

Or use the generated output:
```bash
terraform output ssh_connection_string
```

---

## Variable Configuration

### Using terraform.tfvars
Create `terraform.tfvars` to override defaults:

```hcl
# Example: Using t2.small instead of t2.micro
instance_type = "t2.small"

# Example: Using production environment
my_environment = "prd"

# Example: Using specific region
aws_region = "eu-west-1"
```

### Using Command Line
```bash
terraform apply -var="instance_type=t2.small" -var="my_environment=prod"
```

### Available Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | us-east-1 | AWS region for deployment |
| `ami_id` | ami-0f8a61b66d1accaee | Amazon Linux 2 AMI |
| `instance_type` | t2.micro | EC2 instance size |
| `my_environment` | dev | Environment name (dev/staging/prd) |

---

## Resource Architecture

```
┌─────────────────────────────────────────────────┐
│                    AWS Region                   │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────┐  │
│  │        VPC (10.0.0.0/16)                 │  │
│  │  ┌──────────────────────────────────┐   │  │
│  │  │  Public Subnet (10.0.1.0/24)     │   │  │
│  │  │  ┌──────────────────────────┐    │   │  │
│  │  │  │   EC2 Instance           │    │   │  │
│  │  │  │ - Application Server     │    │   │  │
│  │  │  │ - IAM Role               │    │   │  │
│  │  │  │ - Security Group         │    │   │  │
│  │  │  └──────────────────────────┘    │   │  │
│  │  └──────────────────────────────────┘   │  │
│  │              ↓                           │  │
│  │  ┌──────────────────────────────────┐   │  │
│  │  │  Internet Gateway                │   │  │
│  │  │  (Gateway to Internet)           │   │  │
│  │  └──────────────────────────────────┘   │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
            ↓
    Your Laptop (103.181.90.188/32)
    - SSH Port 22
    - HTTP Port 8080
```

---

## File Descriptions

### `terraform.tf`
- **Purpose**: Core Terraform settings
- **Contains**: Provider configuration, backend settings, required versions
- **Key Settings**: AWS region, default tags

### `variables.tf`
- **Purpose**: Input variables for the configuration
- **Contains**: Variable definitions, descriptions, defaults, validations
- **Key Variables**: AWS region, AMI ID, instance type, environment

### `vpc.tf`
- **Purpose**: Network infrastructure
- **Contains**: VPC, subnets, internet gateway, route tables
- **Key Resources**: VPC, public subnet, internet gateway

### `ec2.tf`
- **Purpose**: EC2 instance and security setup
- **Contains**: EC2 instance, security groups, IAM role, key pair
- **Key Resources**: EC2 instance, security groups, IAM role

### `outputs.tf`
- **Purpose**: Display important information after deployment
- **Contains**: Instance IP, SSH commands, BankApp URL
- **Usage**: Run `terraform output` to view all outputs

### `script.sh`
- **Purpose**: EC2 initialization script
- **Runs**: When EC2 instance starts
- **Contains**: System updates, software installation, application setup

---

## Security Configuration

### Security Groups
- **SSH Access**: Only from your laptop (103.181.90.188/32)
- **HTTP Access**: Only from your laptop (103.181.90.188/32)
- **Outbound**: All traffic allowed (for updates and API calls)

### IAM Role
- **Permissions**: AmazonSSMManagedInstanceCore
- **Purpose**: EC2 can be managed via AWS Systems Manager Session Manager

### Metadata Service
- **IMDSv2 Enforced**: Protects against SSRF attacks
- **Security**: Enhanced credential access security

---

## Common Operations

### View Current Infrastructure
```bash
terraform show
```

### View Outputs
```bash
terraform output
terraform output instance_public_ip
```

### Destroy All Resources
```bash
terraform destroy
```
**Warning**: This will delete all infrastructure. Type `yes` to confirm.

### Update Configuration
```bash
# Edit variables in terraform.tfvars or use -var flag
terraform plan
terraform apply
```

### Refresh State
```bash
terraform refresh
```
Updates local state to match AWS reality.

---

## Troubleshooting

### Issue: "Permission denied (publickey)"
**Solution**: Ensure `terra-automate-key` file has correct permissions:
```bash
chmod 600 terra-automate-key
```

### Issue: "AMI not found"
**Solution**: Verify AMI ID is correct for your region. Different regions have different AMI IDs.

### Issue: "Insufficient capacity"
**Solution**: Try a different availability zone or instance type.

### Issue: Instance not accessible
**Checklist**:
- Security group allows SSH on port 22
- Security group allows HTTP on port 8080
- Your IP address is correctly set (103.181.90.188/32)
- EC2 instance has public IP assigned

---

## Maintenance

### Update EC2 Instance
To modify instance configuration:
```bash
# Edit variables.tf or terraform.tfvars
terraform plan
terraform apply
```

### Add More Resources
1. Edit appropriate `.tf` file
2. Run `terraform plan` to review changes
3. Run `terraform apply` to deploy

### Backup State File
```bash
cp terraform.tfstate terraform.tfstate.backup
```

---

## Next Steps

1. **Deploy Application**: Use `script.sh` to automate BankApp deployment
2. **Enable Monitoring**: Add CloudWatch alarms for EC2 metrics
3. **Setup Backups**: Configure AMI snapshots for disaster recovery
4. **Enable Logging**: Add VPC Flow Logs for network analysis
5. **Production Ready**: Move to S3 backend for team collaboration

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/)
- [BankApp Documentation](../README.md)

---

## Support & Questions

For issues or questions:
1. Check Terraform logs: `terraform show`
2. Review AWS CloudFormation events in console
3. Check EC2 instance system logs for script errors
4. Reference troubleshooting section above

---

**Last Updated**: 2026-09-05  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: ~> 5.0
