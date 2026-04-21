# IaC — CloudFormation: AWS EC2 Instance

This directory contains an AWS **CloudFormation** template that provisions a secure
EC2 instance with VPC, security groups, IAM roles, and CloudWatch monitoring.

> **Purpose:** Demonstrate Infrastructure as Code best practices for deploying
> a production-ready EC2 instance using CloudFormation.

---

## Directory Layout

```
iac-poc-Models/cloudformation/opus/
├── ec2-instance.yaml    # CloudFormation template
└── README.md            # This file
```

---

## Features

- **Secure Configuration**
  - No hardcoded secrets
  - IMDSv2 required (prevents SSRF attacks)
  - Encrypted EBS volumes
  - SSM Session Manager for secure remote access
  - Restrictive security group rules

- **Monitoring**
  - Detailed CloudWatch monitoring enabled
  - CPU utilization alarm
  - Instance status check alarm
  - CloudWatch Agent policy attached

- **Best Practices**
  - Parameterized for reusability
  - Comprehensive tagging
  - Parameter validation with constraints
  - Cross-stack exports for integration

---

## Prerequisites

| Tool | Min Version |
|------|-------------|
| AWS CLI | 2.x |

---

## Quick Start

### Deploy via AWS CLI

```bash
# 1. Authenticate to AWS
aws configure
# or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

# 2. Deploy the stack
aws cloudformation create-stack \
  --stack-name ec2-instance-dev \
  --template-body file://iac-poc-Models/cloudformation/opus/ec2-instance.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=my-app \
    ParameterKey=Environment,ParameterValue=dev

# 3. Wait for stack creation
aws cloudformation wait stack-create-complete \
  --stack-name ec2-instance-dev

# 4. Get outputs
aws cloudformation describe-stacks \
  --stack-name ec2-instance-dev \
  --query 'Stacks[0].Outputs'

# 5. Connect to instance via SSM
INSTANCE_ID=$(aws cloudformation describe-stacks \
  --stack-name ec2-instance-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
  --output text)
aws ssm start-session --target $INSTANCE_ID
```

### Deploy via AWS Console

1. Navigate to CloudFormation in the AWS Console
2. Click "Create stack" → "With new resources"
3. Upload the `ec2-instance.yaml` template
4. Fill in the parameters
5. Acknowledge IAM capabilities
6. Create stack

---

## Parameters

| Parameter | Description | Default | Allowed Values |
|-----------|-------------|---------|----------------|
| `ProjectName` | Name for resource naming and tagging | `ec2-instance` | Lowercase alphanumeric with hyphens |
| `Environment` | Environment label | `dev` | `dev`, `staging`, `prod` |
| `VpcCidr` | CIDR block for the VPC | `10.0.0.0/16` | Valid CIDR |
| `SubnetCidr` | CIDR block for the public subnet | `10.0.1.0/24` | Valid CIDR |
| `InstanceType` | EC2 instance type | `t3.micro` | t3.micro through t3.2xlarge |
| `AmiId` | AMI ID (SSM parameter) | Latest Amazon Linux 2023 | - |
| `KeyName` | SSH key pair name (optional) | `""` | - |
| `RootVolumeSize` | Root EBS volume size in GB | `20` | 8-16384 |
| `RootVolumeType` | Root EBS volume type | `gp3` | `gp3`, `gp2`, `io1`, `io2` |
| `AllowedSshCidrBlock` | CIDR block for SSH access | `""` | Valid CIDR |
| `EnableTerminationProtection` | Enable termination protection | `false` | `true`, `false` |
| `EnableDetailedMonitoring` | Enable detailed monitoring | `true` | `true`, `false` |

---

## Outputs

| Output | Description | Export Name |
|--------|-------------|-------------|
| `InstanceId` | ID of the EC2 instance | `{StackName}-InstanceId` |
| `InstancePublicIp` | Public IP address | `{StackName}-InstancePublicIp` |
| `InstancePrivateIp` | Private IP address | `{StackName}-InstancePrivateIp` |
| `InstancePublicDns` | Public DNS name | `{StackName}-InstancePublicDns` |
| `SecurityGroupId` | Security group ID | `{StackName}-SecurityGroupId` |
| `VpcId` | VPC ID | `{StackName}-VpcId` |
| `SubnetId` | Subnet ID | `{StackName}-SubnetId` |
| `InstanceProfileArn` | IAM instance profile ARN | `{StackName}-InstanceProfileArn` |
| `SSMSessionCommand` | AWS CLI command for SSM session | - |
| `SSHCommand` | SSH command (if key configured) | - |

---

## Security Considerations

1. **IMDSv2 Required**: The instance metadata service requires tokens (v2), preventing SSRF attacks.
2. **Encrypted Volumes**: All EBS volumes are encrypted by default.
3. **SSM Access**: Use SSM Session Manager instead of SSH for secure, auditable access.
4. **Restrictive Security Groups**: SSH access is disabled by default; only enable with specific CIDR blocks.
5. **IAM Least Privilege**: Instance role only includes SSM and CloudWatch policies.

---

## Update Stack

```bash
aws cloudformation update-stack \
  --stack-name ec2-instance-dev \
  --template-body file://iac-poc-Models/cloudformation/opus/ec2-instance.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=my-app \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t3.small
```

---

## Tear-down

```bash
# Delete the stack
aws cloudformation delete-stack --stack-name ec2-instance-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name ec2-instance-dev
```

---

## Validate Template

```bash
# Validate CloudFormation template syntax
aws cloudformation validate-template \
  --template-body file://iac-poc-Models/cloudformation/opus/ec2-instance.yaml

# Security scanning with cfn-lint
cfn-lint iac-poc-Models/cloudformation/opus/ec2-instance.yaml

# Security scanning with checkov
checkov -f iac-poc-Models/cloudformation/opus/ec2-instance.yaml --framework cloudformation
```
