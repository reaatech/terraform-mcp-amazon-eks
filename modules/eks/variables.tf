variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of node group definitions"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = optional(number)
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
  }))
  default = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "cluster_security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Whether the EKS API server is reachable from the VPC"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server is reachable from the public internet"
  type        = bool
  default     = false
}

variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets using KMS"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for envelope encryption of Kubernetes secrets (null to create one automatically)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
