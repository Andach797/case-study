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

variable "project_tag" {
  type = string
}

variable "environment" {
  type = string
}

variable "create_nat_gateway" {
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources in this vpc."
  type        = map(string)
  default     = {}
}
