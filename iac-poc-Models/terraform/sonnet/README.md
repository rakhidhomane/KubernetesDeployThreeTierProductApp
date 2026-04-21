# Terraform EC2 Instance Deployment

This directory contains Terraform configuration to deploy a secure, monitored AWS EC2 instance following best practices.

## Features

- ✅ **Secure Configuration**: No hardcoded secrets, uses IAM roles and instance profiles
- ✅ **Monitoring**: CloudWatch detailed monitoring and custom alarms enabled
- ✅ **Encryption**: EBS volumes encrypted by default
- ✅ **Tagging**: Comprehensive tagging strategy for resource management
- ✅ **Modular**: Fully parameterized and reusable configuration
- ✅ **IMDSv2**: Enhanced metadata service security enabled
- ✅ **SSM Access**: AWS Systems Manager Session Manager for secure access (no SSH keys needed)
- ✅ **CloudWatch Agent**: Pre-configured for logs and custom metrics
- ✅ **Network Security**: Security groups with minimal required access

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions

## Quick Start

### 1. Initialize Terraform

```bash
cd iac-poc-Models/terraform/sonnet
terraform init
```

### 2. Review Variables

Check `variables.tf` for available configuration options. Create a `terraform.tfvars` file for your specific values:

```hcl
# terraform.tfvars
region          = "us-east-1"
environment     = "dev"
instance_name   = "my-web-server"
instance_type   = "t3.micro"
project_name    = "my-project"

# Restrict SSH access to your IP (recommended)
ssh_allowed_cidr_blocks = ["YOUR_IP/32"]

# Optional: Add custom tags
additional_tags = {
  Team  = "DevOps"
  Owner = "john.doe@example.com"
}
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

### 5. Access Your Instance

**Recommended: Use AWS Systems Manager Session Manager**
```bash
# Get the SSM connection command from outputs
terraform output ssm_connection_command

# Or directly:
aws ssm start-session --target <instance-id> --region us-east-1
```

**Alternative: SSH (if key_name is configured)**
```bash
terraform output ssh_connection_command
```

## Important Security Notes

⚠️ **Default Settings**:
- SSH access is open to `0.0.0.0/0` by default for demonstration
- **ALWAYS** restrict `ssh_allowed_cidr_blocks` to your specific IP in production
- Consider disabling SSH entirely and using SSM Session Manager

⚠️ **Production Checklist**:
1. Set `ssh_allowed_cidr_blocks` to specific IPs
2. Configure SNS topic for CloudWatch alarm notifications
3. Enable remote state with S3 backend (see `versions.tf`)
4. Review and adjust security group rules
5. Consider using a custom VPC instead of default VPC
6. Implement backup strategy for EBS volumes

## Configuration Options

### Instance Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `instance_name` | Name of the EC2 instance | `web-server` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `ami_id` | AMI ID (empty = latest Amazon Linux 2023) | `""` |
| `key_name` | SSH key pair name | `""` |

### Network Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `allow_ssh` | Enable SSH access | `true` |
| `allow_http` | Enable HTTP access | `true` |
| `allow_https` | Enable HTTPS access | `true` |
| `ssh_allowed_cidr_blocks` | CIDR blocks for SSH | `["0.0.0.0/0"]` |

### Storage Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `root_volume_type` | EBS volume type | `gp3` |
| `root_volume_size` | Volume size in GB | `20` |
| `enable_encryption` | Enable EBS encryption | `true` |

### Monitoring Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_detailed_monitoring` | Enable detailed CloudWatch monitoring | `true` |
| `enable_cloudwatch_alarms` | Create CloudWatch alarms | `true` |
| `cpu_alarm_threshold` | CPU alarm threshold (%) | `80` |

## Outputs

The configuration provides comprehensive outputs:

- **Instance Details**: ID, ARN, IPs, DNS names
- **Security**: Security group ID, IAM role ARN
- **Connection**: SSH and SSM connection commands
- **Monitoring**: CloudWatch dashboard URL

View all outputs:
```bash
terraform output
```

## Monitoring

The instance comes with:

1. **CloudWatch Detailed Monitoring**: 1-minute metric intervals
2. **CloudWatch Alarms**: CPU utilization and status checks
3. **CloudWatch Agent**: Custom metrics (CPU, memory, disk) and logs
4. **CloudWatch Logs**: System logs collected automatically

Access CloudWatch dashboard:
```bash
terraform output cloudwatch_dashboard_url
```

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

## File Structure

```
.
├── main.tf                # Main Terraform configuration
├── variables.tf           # Input variables
├── outputs.tf            # Output values
├── versions.tf           # Terraform and provider versions
├── user_data.sh.tpl      # User data template script
└── README.md             # This file
```

## Best Practices Implemented

1. **No Hardcoded Secrets**: Uses IAM roles and instance profiles
2. **Least Privilege**: Minimal required IAM permissions
3. **Encryption**: EBS volumes encrypted by default
4. **Monitoring**: Comprehensive CloudWatch integration
5. **Secure Access**: IMDSv2 enforced, SSM preferred over SSH
6. **Tagging Strategy**: Consistent tags for all resources
7. **Network Security**: Security groups with specific rules
8. **Modular Design**: Fully parameterized for reusability
9. **State Management**: Supports remote state backends
10. **Documentation**: Comprehensive inline comments

## Customization

### Using Custom AMI

```hcl
ami_id = "ami-0abcdef1234567890"
```

### Custom User Data

Provide your own user data script:

```hcl
user_data_script = file("${path.module}/my-custom-script.sh")
```

### Configure CloudWatch Alarms

```hcl
enable_cloudwatch_alarms = true
cpu_alarm_threshold      = 70
alarm_actions            = ["arn:aws:sns:us-east-1:123456789012:my-topic"]
```

## Troubleshooting

### Instance Not Accessible

1. Check security group rules: `terraform output security_group_id`
2. Verify instance is running: `aws ec2 describe-instances --instance-ids <id>`
3. Use SSM Session Manager instead of SSH

### CloudWatch Agent Not Working

1. Check IAM role has CloudWatchAgentServerPolicy
2. Verify user data script executed: `/var/log/user-data.log`
3. Check CloudWatch agent status: `systemctl status amazon-cloudwatch-agent`

## Support

For issues or questions:
1. Check AWS CloudWatch Logs: `/aws/ec2/<instance-name>`
2. Review Terraform plan before applying
3. Ensure AWS credentials are properly configured

## License

This configuration is provided as-is for demonstration and educational purposes.
