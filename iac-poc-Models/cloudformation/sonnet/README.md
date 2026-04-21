# CloudFormation EC2 Instance Deployment

This directory contains an AWS CloudFormation template to deploy a secure, monitored EC2 instance following best practices.

## Features

- ✅ **Secure Configuration**: No hardcoded secrets, uses IAM roles and instance profiles
- ✅ **Monitoring**: CloudWatch detailed monitoring and custom alarms enabled
- ✅ **Encryption**: EBS volumes encrypted by default
- ✅ **Tagging**: Comprehensive tagging strategy for resource management
- ✅ **Parameterized**: Fully configurable via CloudFormation parameters
- ✅ **IMDSv2**: Enhanced metadata service security enabled
- ✅ **SSM Access**: AWS Systems Manager Session Manager for secure access (no SSH keys needed)
- ✅ **CloudWatch Agent**: Pre-configured for logs and custom metrics
- ✅ **Network Security**: Security groups with configurable access rules
- ✅ **Email Notifications**: Optional SNS topic for CloudWatch alarms

## Prerequisites

- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- Valid VPC and Subnet IDs in your target region

## Quick Start

### 1. Get VPC and Subnet Information

First, identify your VPC and Subnet IDs:

```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# List Subnets in a VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' --output table
```

### 2. Deploy Using AWS Console

1. Navigate to the CloudFormation console
2. Click "Create stack" → "With new resources"
3. Choose "Upload a template file" and select `ec2-instance.yaml`
4. Fill in the required parameters (VPC ID, Subnet ID, etc.)
5. Review and create the stack

### 3. Deploy Using AWS CLI

Create a parameters file `parameters.json`:

```json
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "my-project"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "dev"
  },
  {
    "ParameterKey": "InstanceName",
    "ParameterValue": "my-web-server"
  },
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "t3.micro"
  },
  {
    "ParameterKey": "VpcId",
    "ParameterValue": "vpc-0123456789abcdef0"
  },
  {
    "ParameterKey": "SubnetId",
    "ParameterValue": "subnet-0123456789abcdef0"
  },
  {
    "ParameterKey": "SSHLocation",
    "ParameterValue": "203.0.113.0/32"
  },
  {
    "ParameterKey": "AlarmEmail",
    "ParameterValue": "alerts@example.com"
  }
]
```

Deploy the stack:

```bash
aws cloudformation create-stack \
  --stack-name my-ec2-instance \
  --template-body file://ec2-instance.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

Monitor stack creation:

```bash
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].StackStatus'
```

### 4. Access Your Instance

**Get stack outputs:**

```bash
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs' \
  --output table
```

**Recommended: Use AWS Systems Manager Session Manager**

```bash
# Get instance ID from stack outputs
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
  --output text)

# Connect via SSM
aws ssm start-session --target $INSTANCE_ID --region us-east-1
```

**Alternative: SSH (if key configured)**

```bash
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
```

## Parameters

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `VpcId` | VPC ID where instance will be deployed | `vpc-0123456789abcdef0` |
| `SubnetId` | Subnet ID within the VPC | `subnet-0123456789abcdef0` |

### Optional Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ProjectName` | Name of the project | `ec2-demo` |
| `Environment` | Environment (dev/staging/prod) | `dev` |
| `InstanceName` | Name tag for the instance | `web-server` |
| `InstanceType` | EC2 instance type | `t3.micro` |
| `KeyName` | SSH key pair name | _(empty)_ |
| `AllowSSH` | Enable SSH access | `true` |
| `SSHLocation` | CIDR for SSH access | `0.0.0.0/0` |
| `AllowHTTP` | Enable HTTP access | `true` |
| `AllowHTTPS` | Enable HTTPS access | `true` |
| `RootVolumeSize` | Root volume size (GB) | `20` |
| `RootVolumeType` | EBS volume type | `gp3` |
| `EnableEncryption` | Enable EBS encryption | `true` |
| `EnableDetailedMonitoring` | Enable detailed monitoring | `true` |
| `EnableCloudWatchAlarms` | Create CloudWatch alarms | `true` |
| `CPUAlarmThreshold` | CPU alarm threshold (%) | `80` |
| `AlarmEmail` | Email for alarm notifications | _(empty)_ |

## Important Security Notes

⚠️ **Default Settings**:
- SSH access is open to `0.0.0.0/0` by default
- **ALWAYS** set `SSHLocation` to your specific IP in production
- Consider setting `AllowSSH` to `false` and using SSM Session Manager exclusively

⚠️ **Production Checklist**:
1. ✅ Set `SSHLocation` to your specific IP address or VPN CIDR
2. ✅ Configure `AlarmEmail` for CloudWatch alarm notifications
3. ✅ Review and adjust security group rules as needed
4. ✅ Use a private subnet for production workloads
5. ✅ Implement backup strategy for EBS volumes
6. ✅ Set appropriate `Environment` tag
7. ✅ Confirm SNS email subscription for alarms

## Stack Outputs

The CloudFormation stack provides the following outputs:

- **InstanceId**: EC2 instance ID
- **InstancePublicIP**: Public IP address
- **InstancePrivateIP**: Private IP address
- **InstancePublicDNS**: Public DNS name
- **SecurityGroupId**: Security group ID
- **IAMRoleName**: IAM role name
- **IAMRoleARN**: IAM role ARN
- **SSMConnectionCommand**: Command to connect via SSM
- **SSHConnectionCommand**: Command to connect via SSH (if configured)
- **CloudWatchDashboardURL**: Link to CloudWatch metrics dashboard
- **CloudWatchLogsGroup**: CloudWatch Logs group name
- **WebURL**: URL to access the web server

View all outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs'
```

## Monitoring

The instance comes with:

1. **CloudWatch Detailed Monitoring**: 1-minute metric intervals (when enabled)
2. **CloudWatch Alarms**: 
   - CPU utilization alarm (threshold configurable)
   - Instance status check alarm
3. **CloudWatch Agent**: Custom metrics (CPU, memory, disk) and logs
4. **CloudWatch Logs**: System logs (`/var/log/messages`, `/var/log/secure`)
5. **SNS Notifications**: Email alerts when alarms trigger (when configured)

Access monitoring:

```bash
# Get CloudWatch dashboard URL from outputs
aws cloudformation describe-stacks \
  --stack-name my-ec2-instance \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudWatchDashboardURL`].OutputValue' \
  --output text
```

## Update Stack

To update the stack with new parameters:

```bash
aws cloudformation update-stack \
  --stack-name my-ec2-instance \
  --template-body file://ec2-instance.yaml \
  --parameters file://updated-parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## Clean Up

To delete all resources:

```bash
aws cloudformation delete-stack --stack-name my-ec2-instance
```

Monitor deletion:

```bash
aws cloudformation wait stack-delete-complete --stack-name my-ec2-instance
```

## Troubleshooting

### Stack Creation Fails

1. **Check IAM permissions**: Ensure you have `CAPABILITY_NAMED_IAM`
2. **Verify VPC/Subnet**: Ensure IDs are valid and in the correct region
3. **Check quotas**: Verify EC2 instance limits in your account
4. **Review events**: 
   ```bash
   aws cloudformation describe-stack-events --stack-name my-ec2-instance
   ```

### Instance Not Accessible

1. **Check security group**: Verify rules allow your IP
2. **Verify instance status**: Check instance is running
   ```bash
   aws ec2 describe-instance-status --instance-ids <instance-id>
   ```
3. **Use SSM instead of SSH**: More reliable for troubleshooting

### CloudWatch Agent Not Working

1. Check IAM role has `CloudWatchAgentServerPolicy`
2. Verify user data executed successfully:
   ```bash
   aws ssm start-session --target <instance-id>
   cat /var/log/user-data.log
   ```
3. Check CloudWatch agent status:
   ```bash
   systemctl status amazon-cloudwatch-agent
   ```

### SNS Email Not Received

1. Check spam folder for confirmation email
2. Verify email address in parameters
3. Confirm SNS subscription in AWS Console

## Best Practices Implemented

1. ✅ **No Hardcoded Secrets**: Uses IAM roles, SSM Parameter Store for AMI ID
2. ✅ **Least Privilege**: Minimal required IAM permissions
3. ✅ **Encryption**: EBS volumes encrypted by default
4. ✅ **Monitoring**: Comprehensive CloudWatch integration
5. ✅ **Secure Access**: IMDSv2 enforced, SSM preferred over SSH
6. ✅ **Tagging Strategy**: Consistent tags for all resources
7. ✅ **Network Security**: Parameterized security group rules
8. ✅ **Modular Design**: Fully parameterized for reusability
9. ✅ **Email Notifications**: Optional SNS topic for alerts
10. ✅ **Documentation**: Comprehensive inline descriptions

## Advanced Usage

### Using Custom AMI

Set the `LatestAmiId` parameter to your custom AMI ID:

```json
{
  "ParameterKey": "LatestAmiId",
  "ParameterValue": "ami-0abcdef1234567890"
}
```

Note: When using a custom AMI, you need to override the default SSM parameter.

### Deploy in Private Subnet

For production, deploy in a private subnet and use a bastion host or VPN:

```json
{
  "ParameterKey": "SubnetId",
  "ParameterValue": "subnet-private123456"
},
{
  "ParameterKey": "AllowSSH",
  "ParameterValue": "false"
}
```

Access via SSM Session Manager (no public IP needed).

### Multiple Environments

Deploy separate stacks for different environments:

```bash
# Development
aws cloudformation create-stack \
  --stack-name ec2-dev \
  --template-body file://ec2-instance.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_NAMED_IAM

# Production
aws cloudformation create-stack \
  --stack-name ec2-prod \
  --template-body file://ec2-instance.yaml \
  --parameters ParameterKey=Environment,ParameterValue=prod \
               ParameterKey=InstanceType,ParameterValue=t3.medium \
  --capabilities CAPABILITY_NAMED_IAM
```

## File Structure

```
.
├── ec2-instance.yaml    # CloudFormation template
└── README.md            # This file
```

## Comparison with Terraform

Both solutions provide equivalent functionality:

| Feature | CloudFormation | Terraform |
|---------|---------------|-----------|
| **Vendor** | AWS-native | Third-party |
| **State Management** | Automatic | Requires S3 backend |
| **Parameter Validation** | Built-in | Via variables |
| **Multi-cloud** | AWS only | Yes |
| **IDE Support** | Good | Excellent |
| **Learning Curve** | Moderate | Moderate |

Choose based on your team's expertise and requirements.

## Support

For issues:
1. Check CloudWatch Logs: `/aws/ec2/<instance-name>`
2. Review CloudFormation events in AWS Console
3. Ensure AWS CLI and credentials are configured correctly

## License

This template is provided as-is for demonstration and educational purposes.
