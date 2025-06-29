variable "name_prefix" {
  description = "Base name; role ⇒ <name_prefix>-irsa, SA ⇒ <name_prefix>-sa"
  type        = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "bucket_arn" {
  description = "S3 bucket ARN the pod may write to"
  type        = string
}

variable "secret_arns" {
  type        = list(string)
  description = "Secrets Manager ARNs the pod may read"
  default     = []
}

variable "oidc_arn" {
  description = "OIDC provider ARN from EKS cluster"
  type        = string
}

variable "oidc_url" {
  description = "OIDC provider URL from EKS cluster"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
