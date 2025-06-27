variable "aws_region" {
  type = string
}
variable "project_tag" {
  type = string
}
variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}
variable "azs" {
  type = list(string)
}
variable "public_subnet_cidrs" {
  type = list(string)
}
variable "private_subnet_cidrs" {
  type = list(string)
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}
