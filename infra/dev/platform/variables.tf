variable "aws_region" {
  type        = string
  description = "Must match the region of the bootstrap layer."
}

variable "project_tag" {
  type        = string
  description = "Same tag used in bootstrap."
}

variable "environment" {
  type        = string
  description = "Environment (dev / prod …)."
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy. Defaults to 'latest'."
  default     = "latest"
}

variable "github_pat" {
  description = "GitHub personal access token with repo:write on case-study"
  type        = string
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Extra tags for all AWS resources created here."
  default     = {}
}
