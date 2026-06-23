#checkov:skip=CKV2_AWS_11: VPC Flow Logs not required for learning project

# ============================================
# Key Pair
# ============================================

resource "aws_key_pair" "my_key_pair" {
  key_name   = "terra-automate-key-josh"
  public_key = file("terra-automate-key.pub")
}

# ============================================
# Default Security Group
# ============================================

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name = "default-sg"
  }
}


# ============================================
# Security Group
# ============================================

resource "aws_security_group" "my_security_group" {
  name        = "${var.my_environment}-security-group"
  vpc_id      = aws_vpc.main.id
  description = "Inbound and outbound rules for EC2 instance"
}

# ============================================
# Ingress Rules
# ============================================

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.my_security_group.id
  description       = "Allow BankApp HTTP Traffic"
  cidr_ipv4         = "103.181.90.188/32"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

#resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
#  security_group_id = aws_security_group.my_security_group.id
#  description       = "Allow SSH from my laptop"
#  cidr_ipv4         = "103.181.90.188/32"
#  from_port         = 22
#  to_port           = 22
#  ip_protocol       = "tcp"
#}

# ============================================
# Egress Rules
# ============================================

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.my_security_group.id
  description       = "Allow outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ============================================
# IAM Role
# ============================================

resource "aws_iam_role" "ec2_role" {
  name = "${var.my_environment}-BankAppEC2Role"

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
}

# ============================================
# IAM Policy Attachment
# ============================================

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ============================================
# IAM Instance Profile
# ============================================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.my_environment}-BankAppInstanceProfile"
  role = aws_iam_role.ec2_role.name
}

# ============================================
# EC2 Instance
# ============================================

resource "aws_instance" "my_instance" {

  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.my_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  subnet_id            = aws_subnet.public.id

  ebs_optimized = true
  monitoring    = true

  depends_on = [
    aws_key_pair.my_key_pair
  ]

  metadata_options {
    http_tokens = "required"
  }

  vpc_security_group_ids = [
    aws_security_group.my_security_group.id
  ]

  user_data = file("script.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.my_environment}-terra-automate-server"
    Environment = var.my_environment
  }
}
