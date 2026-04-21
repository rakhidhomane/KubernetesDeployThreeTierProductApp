#!/bin/bash
# User data script for EC2 instance initialization
# This script runs on first boot

set -e

# Update system packages
yum update -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/${instance_name}",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/aws/ec2/${instance_name}",
            "log_stream_name": "{instance_id}/secure"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "EC2/Custom",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          },
          {
            "name": "cpu_usage_iowait",
            "rename": "CPU_IOWAIT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Install and configure SSM agent (usually pre-installed on Amazon Linux 2023)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install common utilities
yum install -y \
  htop \
  git \
  wget \
  curl \
  vim

# Create a sample web page (optional - for testing)
yum install -y httpd
systemctl enable httpd
systemctl start httpd

cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <title>EC2 Instance - ${instance_name}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 50px;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #232f3e;
        }
        .info {
            background-color: #f9f9f9;
            padding: 15px;
            border-left: 4px solid #ff9900;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 EC2 Instance Running Successfully</h1>
        <div class="info">
            <p><strong>Instance Name:</strong> ${instance_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Managed By:</strong> Terraform</p>
        </div>
        <p>This instance was provisioned using Infrastructure as Code best practices.</p>
        <ul>
            <li>✅ Secure configuration (no hardcoded secrets)</li>
            <li>✅ CloudWatch monitoring enabled</li>
            <li>✅ SSM access configured</li>
            <li>✅ Encrypted storage</li>
            <li>✅ Proper IAM roles</li>
            <li>✅ Tagged resources</li>
        </ul>
    </div>
</body>
</html>
HTML

# Log completion
echo "User data script completed successfully" >> /var/log/user-data.log
