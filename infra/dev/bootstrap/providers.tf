terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Started to fail randomly for 6.0
    version = "~> 6.0.0" }
  }
}

provider "aws" {
  region = var.aws_region
}
