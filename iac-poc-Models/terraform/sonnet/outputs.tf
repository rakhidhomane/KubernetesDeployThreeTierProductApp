###############################################################################
# EC2 Instance Outputs
###############################################################################

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
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

output "instance_private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.main.private_dns
}

output "instance_state" {
  description = "State of the EC2 instance"
  value       = aws_instance.main.instance_state
}

###############################################################################
# Security Group Outputs
###############################################################################

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.ec2.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.ec2.name
}

###############################################################################
# IAM Outputs
###############################################################################

output "iam_role_name" {
  description = "Name of the IAM role attached to the instance"
  value       = aws_iam_role.ec2.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2.arn
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

###############################################################################
# Connection Information
###############################################################################

output "ssh_connection_command" {
  description = "SSH connection command (if SSH is enabled and key is configured). Note: Adjust the key file path as needed."
  value       = var.key_name != "" ? "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_instance.main.public_ip}" : "SSH key not configured. Use AWS Systems Manager Session Manager instead."
  sensitive   = true
}

output "ssm_connection_command" {
  description = "AWS Systems Manager Session Manager connection command (recommended)"
  value       = "aws ssm start-session --target ${aws_instance.main.id} --region ${var.region}"
}

###############################################################################
# Monitoring Outputs
###############################################################################

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard for the instance"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#metricsV2:graph=~();query=~'*7bAWS*2fEC2*2cInstanceId*7d*20${aws_instance.main.id}"
}

output "cloudwatch_logs_group" {
  description = "CloudWatch Logs group name (if logs are configured)"
  value       = "/aws/ec2/${var.instance_name}"
}

###############################################################################
# Resource Tags
###############################################################################

output "instance_tags" {
  description = "Tags applied to the EC2 instance"
  value       = aws_instance.main.tags_all
}
