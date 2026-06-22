output "ec2_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.my_instance.arn
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.my_instance.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS address of the EC2 instance"
  value       = aws_instance.my_instance.public_dns
}