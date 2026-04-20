variable "release_name" {
  description = "Helm release name for KEDA"
  type        = string
  default     = "keda"
}

variable "namespace" {
  description = "Kubernetes namespace for the KEDA operator"
  type        = string
  default     = "keda"
}

variable "create_namespace" {
  description = "Create the KEDA namespace during Helm install"
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Optional pinned KEDA chart version; null uses the latest chart from the repository"
  type        = string
  default     = null
}

variable "values" {
  description = "Additional raw Helm values for the KEDA chart"
  type        = list(string)
  default     = []
}
