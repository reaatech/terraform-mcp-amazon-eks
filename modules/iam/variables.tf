variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  type        = string
}

variable "service_accounts" {
  description = "Map of service account definitions for IRSA"
  type = map(object({
    namespace       = string
    policies        = list(string)
    inline_policies = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
