# Infrastructure as Code - EC2 Instance Deployment

This directory contains Infrastructure as Code (IaC) templates for deploying a secure AWS EC2 instance using both **Terraform** and **CloudFormation**.

## 📁 Directory Structure

```
iac-poc-Models/
├── terraform/
│   └── sonnet/
│       ├── main.tf                    # Main Terraform configuration
│       ├── variables.tf               # Input variables
│       ├── outputs.tf                 # Output values
│       ├── versions.tf                # Provider versions
│       ├── user_data.sh.tpl           # User data template
│       ├── terraform.tfvars.example   # Example variables file
│       └── README.md                  # Terraform documentation
└── cloudformation/
    └── sonnet/
        ├── ec2-instance.yaml          # CloudFormation template
        ├── parameters-example.json    # Example parameters
        └── README.md                  # CloudFormation documentation
```

## ✨ Features

Both implementations provide:

- ✅ **Secure Configuration**: No hardcoded secrets, uses IAM roles
- ✅ **Monitoring**: CloudWatch detailed monitoring and alarms
- ✅ **Encryption**: EBS volumes encrypted by default
- ✅ **Tagging**: Comprehensive tagging strategy
- ✅ **Parameterized**: Fully configurable
- ✅ **IMDSv2**: Enhanced metadata service security
- ✅ **SSM Access**: Systems Manager Session Manager support
- ✅ **CloudWatch Agent**: Pre-configured for logs and metrics
- ✅ **Modular/Reusable**: Best practices for maintainability

## 🚀 Quick Start

### Choose Your Tool

#### Terraform (Recommended for multi-cloud or existing Terraform workflows)

```bash
cd iac-poc-Models/terraform/sonnet

# Initialize
terraform init

# Review plan
terraform plan

# Deploy
terraform apply
```

**Documentation**: See [terraform/sonnet/README.md](terraform/sonnet/README.md)

#### CloudFormation (Recommended for AWS-native teams)

```bash
cd iac-poc-Models/cloudformation/sonnet

# Deploy via AWS CLI
aws cloudformation create-stack \
  --stack-name my-ec2-instance \
  --template-body file://ec2-instance.yaml \
  --parameters file://parameters-example.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Documentation**: See [cloudformation/sonnet/README.md](cloudformation/sonnet/README.md)

## 🔐 Security Best Practices

Both implementations follow AWS security best practices:

1. **No Hardcoded Credentials**: Uses IAM roles and instance profiles
2. **Encryption at Rest**: EBS volumes encrypted by default
3. **IMDSv2 Enforced**: Enhanced metadata service security
4. **Secure Access**: SSM Session Manager preferred over SSH
5. **Network Isolation**: Security groups with minimal required access
6. **Monitoring**: CloudWatch alarms for proactive detection
7. **Least Privilege**: IAM roles with minimal required permissions

### ⚠️ Important Security Notes

**Before deploying to production:**

1. **Restrict SSH Access**: Change `ssh_allowed_cidr_blocks` / `SSHLocation` from `0.0.0.0/0` to your specific IP
2. **Disable SSH**: Consider disabling SSH entirely and using SSM Session Manager
3. **Private Subnets**: Deploy production workloads in private subnets
4. **Alarm Notifications**: Configure SNS topics for CloudWatch alarms
5. **Backup Strategy**: Implement EBS snapshot lifecycle policies

## 📊 Comparison: Terraform vs CloudFormation

| Feature | Terraform | CloudFormation |
|---------|-----------|----------------|
| **Vendor Lock-in** | Multi-cloud | AWS-only |
| **State Management** | External (S3) | Automatic |
| **Language** | HCL | YAML/JSON |
| **Plan Preview** | `terraform plan` | Change sets |
| **IDE Support** | Excellent | Good |
| **Community** | Very large | AWS-focused |
| **Cost** | Free (OSS) | Free |
| **Best For** | Multi-cloud, IaC experts | AWS-native teams |

Both solutions provide **identical functionality** and follow the **same best practices**.

## 🎯 Use Cases

### Development Environment
- Quick testing and experimentation
- Cost-effective instance types (t3.micro)
- Public subnet with SSH access for convenience

### Staging Environment
- Production-like configuration
- Restricted access (specific IP ranges)
- Enhanced monitoring and alarms

### Production Environment
- Private subnet deployment
- No SSH access (SSM only)
- Comprehensive monitoring and alerting
- Automated backups
- Multiple availability zones

## 📦 What Gets Deployed

Both solutions deploy:

1. **EC2 Instance**: 
   - Amazon Linux 2023
   - Configurable instance type
   - Encrypted EBS volume
   - IMDSv2 enabled

2. **Security Group**:
   - SSH (port 22) - configurable
   - HTTP (port 80) - configurable
   - HTTPS (port 443) - configurable

3. **IAM Role & Instance Profile**:
   - CloudWatch Agent permissions
   - SSM Session Manager permissions

4. **CloudWatch Resources**:
   - Detailed monitoring
   - Custom metrics (CPU, memory, disk)
   - Log group for system logs
   - CPU utilization alarm
   - Status check alarm

5. **Optional**:
   - SNS topic for alarm notifications (CloudFormation)
   - Email subscriptions for alarms

## 💰 Cost Estimation

Approximate monthly costs for `t3.micro` in `us-east-1`:

- **EC2 Instance**: ~$7.50/month
- **EBS Volume (20GB gp3)**: ~$1.60/month
- **CloudWatch Detailed Monitoring**: ~$2.10/month
- **CloudWatch Logs (1GB)**: ~$0.50/month
- **CloudWatch Alarms (2)**: ~$0.20/month

**Total**: ~$12/month (may vary by region and usage)

> Use [AWS Pricing Calculator](https://calculator.aws/) for accurate estimates.

## 🧪 Testing

### Validate Terraform

```bash
cd terraform/sonnet
terraform init
terraform validate
terraform fmt -check
```

### Validate CloudFormation

```bash
cd cloudformation/sonnet
aws cloudformation validate-template --template-body file://ec2-instance.yaml
```

### Security Scanning

```bash
# Terraform security scan
checkov -d terraform/sonnet

# CloudFormation security scan
cfn-lint cloudformation/sonnet/ec2-instance.yaml
```

## 📝 Customization Examples

### 1. Change Instance Type

**Terraform**:
```hcl
instance_type = "t3.medium"
```

**CloudFormation**:
```json
{"ParameterKey": "InstanceType", "ParameterValue": "t3.medium"}
```

### 2. Use Custom AMI

**Terraform**:
```hcl
ami_id = "ami-0abcdef1234567890"
```

**CloudFormation**:
```json
{"ParameterKey": "LatestAmiId", "ParameterValue": "ami-0abcdef1234567890"}
```

### 3. Restrict SSH to Specific IP

**Terraform**:
```hcl
ssh_allowed_cidr_blocks = ["203.0.113.25/32"]
```

**CloudFormation**:
```json
{"ParameterKey": "SSHLocation", "ParameterValue": "203.0.113.25/32"}
```

## 🔧 Maintenance

### Update Terraform

```bash
cd terraform/sonnet
terraform plan   # Review changes
terraform apply  # Apply updates
```

### Update CloudFormation

```bash
aws cloudformation update-stack \
  --stack-name my-ec2-instance \
  --template-body file://ec2-instance.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## 🗑️ Clean Up

### Terraform

```bash
cd terraform/sonnet
terraform destroy
```

### CloudFormation

```bash
aws cloudformation delete-stack --stack-name my-ec2-instance
```

## 📚 Additional Resources

- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [CloudWatch Agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)

## 🤝 Contributing

To improve these templates:

1. Test changes thoroughly
2. Update documentation
3. Follow existing code style
4. Add comments for complex logic
5. Validate with security scanners

## 📄 License

These templates are provided as-is for demonstration and educational purposes.

---

**Questions or Issues?** 

Check the README files in each subdirectory for detailed documentation:
- [Terraform Documentation](terraform/sonnet/README.md)
- [CloudFormation Documentation](cloudformation/sonnet/README.md)
