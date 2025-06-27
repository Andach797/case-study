variable "name" {
  type = string
}

variable "days_to_glacier" {
  type    = number
  default = 30
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
