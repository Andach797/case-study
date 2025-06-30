variable "repo_owner" {
  description = "GitHub organization or user (e.g. Andach797)"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name (e.g. case-study)"
  type        = string
}

variable "backend_bucket" {
  description = "S3 bucket for Terraform state backend"
  type        = string
}

variable "csv_bucket" {
  description = "S3 bucket for csv"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for Terraform state lock"
  type        = string
}

variable "role_name" {
  description = "Optional custom name for the IAM role"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Messed up creating this with gha_ci_role module so this is needed lol.
variable "oidc_provider_arn" {
  type        = string
  description = "Pass in the OIDC provider ARN from gha_ci_role so we can trust it."
}
