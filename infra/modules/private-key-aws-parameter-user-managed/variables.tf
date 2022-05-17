variable "instance_id" {
  type        = string
  description = "uniquely ids psoxy instance within AWS account"
}

variable "private_key_id" {
  type        = string
  description = "id of private key"
}

variable "private_key" {
  type        = string
  description = "value of the key"
}

variable "user_managed_value" {
  type        = bool
  description = "whether value is managed by user or not"
  default     = false
}
