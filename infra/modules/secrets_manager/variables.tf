variable "name" {
  description = "The name of the Secrets Manager secret"
  type        = string
}

variable "description" {
  description = "A description for the secret"
  type        = string
  default     = ""
}

variable "secret_kv" {
  description = "Key/value pairs to store in the secret"
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}
