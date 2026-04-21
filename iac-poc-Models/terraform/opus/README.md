# IaC — Terraform: AWS EC2 Instance

This directory contains a **Terraform** configuration that provisions a secure
AWS EC2 instance with VPC, security groups, IAM roles, and CloudWatch monitoring.

> **Purpose:** Demonstrate Infrastructure as Code best practices for deploying
> a production-ready EC2 instance using Terraform.

---

## Directory Layout

```
iac-poc-Models/terraform/opus/
├── main.tf          # Main resources (VPC, EC2, Security Groups, IAM, CloudWatch)
├── variables.tf     # Input variables for customization
├── outputs.tf       # Exported values (instance ID, IPs, etc.)
├── versions.tf      # Required providers & Terraform version
└── README.md        # This file
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
  - Modular and reusable design
  - Comprehensive tagging
  - Variable validation
  - Lifecycle rules to prevent AMI drift

---

## Prerequisites

| Tool | Min Version |
|------|-------------|
| Terraform | 1.5+ |
| AWS CLI | 2.x |

---

## Quick Start

```bash
# 1. Authenticate to AWS
aws configure
# or export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY

# 2. Initialize Terraform
cd iac-poc-Models/terraform/opus
terraform init

# 3. Preview changes
terraform plan

# 4. Apply (creates EC2 instance and supporting resources)
terraform apply

# 5. Connect to instance via SSM
aws ssm start-session --target $(terraform output -raw instance_id)
```

---

## Customization

Create a `terraform.tfvars` file to customize the deployment:

```hcl
# terraform.tfvars
region                    = "us-west-2"
environment               = "prod"
project_name              = "my-app"
instance_type             = "t3.small"
root_volume_size          = 50
enable_detailed_monitoring = true
enable_termination_protection = true

# Optional: SSH access (only if needed)
key_name                  = "my-ssh-key"
allowed_ssh_cidr_blocks   = ["10.0.0.0/8"]

# Additional tags
tags = {
  Owner      = "team-platform"
  CostCenter = "engineering"
}
```

---

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region to deploy into | `us-east-1` |
| `environment` | Environment label (dev, staging, prod) | `dev` |
| `project_name` | Name for resource naming and tagging | `ec2-instance` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `ami_id` | AMI ID (defaults to latest Amazon Linux 2023) | `""` |
| `vpc_cidr` | CIDR block for the VPC | `10.0.0.0/16` |
| `subnet_cidr` | CIDR block for the public subnet | `10.0.1.0/24` |
| `key_name` | SSH key pair name (optional) | `""` |
| `root_volume_size` | Root EBS volume size in GB | `20` |
| `root_volume_type` | Root EBS volume type | `gp3` |
| `enable_detailed_monitoring` | Enable detailed CloudWatch monitoring | `true` |
| `allowed_ssh_cidr_blocks` | CIDR blocks allowed for SSH | `[]` |
| `allowed_http_cidr_blocks` | CIDR blocks allowed for HTTP | `["0.0.0.0/0"]` |
| `allowed_https_cidr_blocks` | CIDR blocks allowed for HTTPS | `["0.0.0.0/0"]` |
| `enable_termination_protection` | Enable termination protection | `false` |
| `tags` | Additional tags for all resources | `{}` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Public IP address |
| `instance_private_ip` | Private IP address |
| `instance_public_dns` | Public DNS name |
| `instance_arn` | ARN of the instance |
| `security_group_id` | Security group ID |
| `vpc_id` | VPC ID |
| `subnet_id` | Subnet ID |
| `ssm_session_command` | AWS CLI command for SSM session |
| `ssh_command` | SSH command (if key configured) |

---

## Security Considerations

1. **IMDSv2 Required**: The instance metadata service requires tokens (v2), preventing SSRF attacks.
2. **Encrypted Volumes**: All EBS volumes are encrypted by default.
3. **SSM Access**: Use SSM Session Manager instead of SSH for secure, auditable access.
4. **Restrictive Security Groups**: SSH access is disabled by default; only enable with specific CIDR blocks.
5. **IAM Least Privilege**: Instance role only includes SSM and CloudWatch policies.

---

## Tear-down

```bash
# Destroy all resources
terraform destroy
```

---

## Security Scanning

```bash
# Checkov — static IaC security scanner
checkov -d iac-poc-Models/terraform/opus --framework terraform

# Trivy — misconfiguration scanner
trivy config iac-poc-Models/terraform/opus
```
