###############################################################################
# Provider Configuration
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
      var.tags
    )
  }
}

###############################################################################
# Data Sources
###############################################################################

# Get the latest Amazon Linux 2023 AMI if no AMI ID is provided
data "aws_ami" "amazon_linux" {
  count       = var.ami_id == "" ? 1 : 0
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
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = var.associate_public_ip

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "instance" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

# SSH access (only if CIDR blocks are provided)
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  count             = length(var.allowed_ssh_cidr_blocks) > 0 ? length(var.allowed_ssh_cidr_blocks) : 0
  security_group_id = aws_security_group.instance.id
  description       = "SSH access"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidr_blocks[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-ssh-${count.index}"
  }
}

# HTTP access
resource "aws_vpc_security_group_ingress_rule" "http" {
  count             = length(var.allowed_http_cidr_blocks) > 0 ? length(var.allowed_http_cidr_blocks) : 0
  security_group_id = aws_security_group.instance.id
  description       = "HTTP access"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_http_cidr_blocks[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-http-${count.index}"
  }
}

# HTTPS access
resource "aws_vpc_security_group_ingress_rule" "https" {
  count             = length(var.allowed_https_cidr_blocks) > 0 ? length(var.allowed_https_cidr_blocks) : 0
  security_group_id = aws_security_group.instance.id
  description       = "HTTPS access"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_https_cidr_blocks[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-https-${count.index}"
  }
}

# Egress rule - allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.instance.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-${var.environment}-egress"
  }
}

###############################################################################
# IAM Role and Instance Profile
###############################################################################

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  count              = var.instance_profile_name == "" ? 1 : 0
  name               = "${var.project_name}-${var.environment}-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-role"
  }
}

# Attach SSM policy for secure remote access without SSH
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count      = var.instance_profile_name == "" ? 1 : 0
  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy for enhanced monitoring
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  count      = var.instance_profile_name == "" ? 1 : 0
  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance" {
  count = var.instance_profile_name == "" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-instance-profile"
  role  = aws_iam_role.instance[0].name

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-profile"
  }
}

###############################################################################
# EC2 Instance
###############################################################################

resource "aws_instance" "main" {
  ami                     = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux[0].id
  instance_type           = var.instance_type
  subnet_id               = aws_subnet.public.id
  vpc_security_group_ids  = [aws_security_group.instance.id]
  iam_instance_profile    = var.instance_profile_name != "" ? var.instance_profile_name : aws_iam_instance_profile.instance[0].name
  key_name                = var.key_name != "" ? var.key_name : null
  monitoring              = var.enable_detailed_monitoring
  disable_api_termination = var.enable_termination_protection

  # IMDSv2 required for security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-${var.environment}-root-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-instance"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

###############################################################################
# CloudWatch Alarms for Monitoring
###############################################################################

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors EC2 CPU utilization"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${var.project_name}-${var.environment}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This alarm monitors EC2 instance status checks"

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-status-alarm"
  }
}
