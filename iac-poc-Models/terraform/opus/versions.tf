###############################################################################
# Terraform and Provider Version Constraints
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment and configure to store state remotely (recommended for teams).
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "ec2-instance/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
