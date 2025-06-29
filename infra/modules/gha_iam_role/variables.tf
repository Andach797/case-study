variable "repo_owner" {
  description = "GitHub organisation / user (e.g. Andach797)"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository (e.g. case-study)"
  type        = string
}

variable "ecr_repo_arn" {
  description = "ARN of the ECR repository the workflow will push to"
  type        = string
}

variable "role_name" {
  description = "Optional custom name for the IAM role"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
