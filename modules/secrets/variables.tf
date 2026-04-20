variable "secrets" {
  description = "Map of secret definitions"
  type = map(object({
    secret_id   = string
    description = optional(string, "")
    kms_key_id  = optional(string)
  }))
}

variable "secret_values" {
  description = "Map of secret values (optional - secrets can be created empty)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "access_roles" {
  description = "List of IAM role ARNs that should have access to the secrets"
  type        = list(string)
  default     = []
}

variable "recovery_window_in_days" {
  description = "Number of days to wait before deleting a secret (0 = immediate)"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
