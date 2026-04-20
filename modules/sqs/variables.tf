variable "queues" {
  description = "Map of queue definitions"
  type = map(object({
    visibility_timeout_seconds  = optional(number, 30)
    message_retention_seconds   = optional(number, 345600) # 4 days
    delay_seconds               = optional(number, 0)
    receive_wait_time_seconds   = optional(number, 20) # Long polling
    content_based_deduplication = optional(bool, false)
    fifo_queue                  = optional(bool, false)
  }))
}

variable "dead_letter_queue" {
  description = "Name of the dead letter queue (optional)"
  type        = string
  default     = null
}

variable "kms_master_key_id" {
  description = "KMS key ID for server-side encryption (null to create one automatically)"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Number of times a message can be received before being sent to DLQ"
  type        = number
  default     = 5
}

variable "queue_policies" {
  description = "Optional queue policies for cross-account access"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
