###############################################################################
# Output Values
###############################################################################

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.instance.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = var.instance_profile_name != "" ? null : aws_iam_instance_profile.instance[0].arn
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = var.region
}

output "ssm_session_command" {
  description = "AWS CLI command to start an SSM session to the instance"
  value       = "aws ssm start-session --target ${aws_instance.main.id} --region ${var.region}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance (if key_name is provided)"
  value       = var.key_name != "" ? "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.main.public_ip}" : "SSH key not configured. Use SSM Session Manager for access."
}
