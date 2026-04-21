###############################################################################
# General Configuration
###############################################################################

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|me|af)-(north|south|east|west|central|northeast|southeast|southwest)-[0-9]$", var.region))
    error_message = "Must be a valid AWS region."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ec2-demo"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

###############################################################################
# EC2 Instance Configuration
###############################################################################

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "web-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "Must be a valid EC2 instance type."
  }
}

variable "ami_id" {
  description = "AMI ID to use for the instance. If empty, uses the latest Amazon Linux 2023 AMI"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Leave empty to disable SSH key-based access (recommended: use SSM instead)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "user_data_script" {
  description = "User data script to run on instance launch. If empty, uses default template"
  type        = string
  default     = ""
}

###############################################################################
# Network Configuration
###############################################################################

variable "use_default_vpc" {
  description = "Whether to use the default VPC"
  type        = bool
  default     = true
}

variable "allow_ssh" {
  description = "Whether to allow SSH access to the instance"
  type        = bool
  default     = true
}

variable "ssh_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access SSH. Restrict to your IP in production"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Open to all. Restrict in production!

  validation {
    condition = alltrue([
      for cidr in var.ssh_allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All elements must be valid CIDR blocks."
  }
}

variable "allow_http" {
  description = "Whether to allow HTTP access to the instance"
  type        = bool
  default     = true
}

variable "http_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.http_allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All elements must be valid CIDR blocks."
  }
}

variable "allow_https" {
  description = "Whether to allow HTTPS access to the instance"
  type        = bool
  default     = true
}

variable "https_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.https_allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All elements must be valid CIDR blocks."
  }
}

###############################################################################
# Storage Configuration
###############################################################################

variable "root_volume_type" {
  description = "Type of root volume (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp2, gp3, io1, or io2."
  }
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "delete_volume_on_termination" {
  description = "Whether to delete the root volume when the instance is terminated"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Whether to enable EBS encryption"
  type        = bool
  default     = true
}

###############################################################################
# Monitoring Configuration
###############################################################################

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute intervals)"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the instance"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold >= 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 0 and 100."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}
