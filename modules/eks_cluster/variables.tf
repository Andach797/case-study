variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "k8s_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API server endpoint should be publicly accessible"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Whether the EKS API server endpoint should be accessible within the VPC"
  type        = bool
  default     = true
}

variable "managed_node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = optional(map(string))
    disk_size      = optional(number)
    ami_type       = optional(string)
  }))
  default = {}
}

variable "project_tag" {
  description = "Project name tag to apply to resources"
  type        = string
}

variable "environment" {
  description = "Environment name tag to apply to resources"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
