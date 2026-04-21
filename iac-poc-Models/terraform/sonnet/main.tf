###############################################################################
# Provider configuration
###############################################################################

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "terraform"
      },
      var.additional_tags
    )
  }
}

###############################################################################
# Data sources
###############################################################################

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get default VPC (or create a custom VPC in production)
data "aws_vpc" "default" {
  default = var.use_default_vpc
}

# Get available subnets in the VPC
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "ec2" {
  name_prefix = "${var.instance_name}-sg-"
  description = "Security group for ${var.instance_name} EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH access (restrict in production to specific IP ranges)
  dynamic "ingress" {
    for_each = var.allow_ssh ? { enabled = true } : {}
    content {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidr_blocks
    }
  }

  # HTTP access
  dynamic "ingress" {
    for_each = var.allow_http ? { enabled = true } : {}
    content {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.http_allowed_cidr_blocks
    }
  }

  # HTTPS access
  dynamic "ingress" {
    for_each = var.allow_https ? { enabled = true } : {}
    content {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.https_allowed_cidr_blocks
    }
  }

  # Outbound rules - allow all egress
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# IAM Role and Instance Profile
###############################################################################

# IAM role for EC2 instance
resource "aws_iam_role" "ec2" {
  name_prefix = "${var.instance_name}-role-"
  description = "IAM role for ${var.instance_name} EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.instance_name}-role"
  }
}

# Attach CloudWatch agent policy for monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM policy for Systems Manager access (secure alternative to SSH)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.instance_name}-profile-"
  role        = aws_iam_role.ec2.name

  tags = {
    Name = "${var.instance_name}-instance-profile"
  }
}

###############################################################################
# EC2 Instance
###############################################################################

resource "aws_instance" "main" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.available.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # Use key_name only if provided (not recommended - use SSM instead)
  key_name = var.key_name != "" ? var.key_name : null

  # EBS root volume configuration
  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.delete_volume_on_termination
    encrypted             = var.enable_encryption

    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  # Enable detailed monitoring
  monitoring = var.enable_detailed_monitoring

  # User data script for initial configuration
  user_data = var.user_data_script != "" ? var.user_data_script : templatefile("${path.module}/user_data.sh.tpl", {
    instance_name = var.instance_name
    environment   = var.environment
  })

  # Metadata options for enhanced security (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = var.instance_name
  }

  lifecycle {
    ignore_changes = [
      # Ignore AMI changes to prevent accidental recreation
      ami,
    ]
  }
}

###############################################################################
# CloudWatch Alarms (optional but recommended)
###############################################################################

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.instance_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.instance_name}-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.instance_name}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 instance status checks"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.instance_name}-status-check-alarm"
  }
}
