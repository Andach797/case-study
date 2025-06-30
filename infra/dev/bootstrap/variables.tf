##############################
# Global parameters
##############################

variable "aws_region" {
  type        = string
  description = "AWS region for the whole stack."
}

variable "project_tag" {
  type        = string
  description = "Project prefix used in resource names."
}

variable "environment" {
  type        = string
  description = "Environment name."
}


# Network / VPC


variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to use (two or more)."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets."
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to **all** AWS resources."
  default     = {}
}
