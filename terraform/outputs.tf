# ============================================
# Terraform Outputs
# ============================================
# These outputs display important information after terraform apply
# You can view all outputs with: terraform output
# Or individual outputs with: terraform output <name>

# ============================================
# EC2 Instance Outputs
# ============================================

output "instance_public_ip" {
  description = "Public IP address to access the BankApp server"
  value       = aws_instance.main.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID (use for AWS Console lookup)"
  value       = aws_instance.main.id
}

output "bankapp_url" {
  description = "URL to access BankApp application (http://<IP>:8080)"
  value       = "http://${aws_instance.main.public_ip}:8080"
}

output "ssh_connection_string" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i terra-automate-key ec2-user@${aws_instance.main.public_ip}"
}
