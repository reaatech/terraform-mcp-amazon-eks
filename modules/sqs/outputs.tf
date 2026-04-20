output "queue_urls" {
  description = "Map of queue names to their URLs"
  value       = { for k, v in aws_sqs_queue.this : k => v.url }
}

output "queue_arns" {
  description = "Map of queue names to their ARNs"
  value       = { for k, v in aws_sqs_queue.this : k => v.arn }
}

output "dlq_url" {
  description = "URL of the dead letter queue (if created)"
  value       = try(aws_sqs_queue.dlq[0].url, null)
}

output "dlq_arn" {
  description = "ARN of the dead letter queue (if created)"
  value       = try(aws_sqs_queue.dlq[0].arn, null)
}
