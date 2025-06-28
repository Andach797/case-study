variable "name" {
  description = "Logical name prefix for the EFS resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create Mount Targets"
  type        = string
}

variable "subnet_ids" {
  description = "List of one subnet per AZ where mount targets will be placed"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups (e.g. EKS node SG) allowed to NFS-mount the file system"
  type        = list(string)
}

variable "create_access_point" {
  description = "Create a POSIX-isolated Access Point"
  type        = bool
  default     = true
}

variable "posix_uid" {
  description = "UID for the root directory owner when using the access point"
  type        = number
  default     = 1000
}

variable "posix_gid" {
  description = "GID for the root directory owner when using the access point"
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags to add to all resources"
  type        = map(string)
  default     = {}
}
