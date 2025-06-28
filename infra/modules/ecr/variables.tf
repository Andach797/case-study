variable "name" {
  description = "Repository name, e.g. web-app"
  type        = string
}

variable "image_scan_on_push" {
  description = "Enable ECR image scanning"
  type        = bool
  default     = true
}

variable "max_images" {
  description = "How many images to keep (lifecycle)"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
