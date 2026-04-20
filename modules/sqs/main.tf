# KMS key for SQS encryption
resource "aws_kms_key" "sqs" {
  count = var.kms_master_key_id == null ? 1 : 0

  description             = "KMS key for SQS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.tags
}

# Main SQS Queues
resource "aws_sqs_queue" "this" {
  for_each = var.queues

  name                        = each.key
  visibility_timeout_seconds  = each.value.visibility_timeout_seconds
  message_retention_seconds   = each.value.message_retention_seconds
  delay_seconds               = each.value.delay_seconds
  receive_wait_time_seconds   = each.value.receive_wait_time_seconds
  content_based_deduplication = each.value.content_based_deduplication
  fifo_queue                  = each.value.fifo_queue
  kms_master_key_id           = var.kms_master_key_id != null ? var.kms_master_key_id : try(aws_kms_key.sqs[0].arn, null)

  tags = merge(var.tags, {
    Name = each.key
  })
}

# Dead Letter Queue (if specified)
resource "aws_sqs_queue" "dlq" {
  count = var.dead_letter_queue != null ? 1 : 0

  name              = var.dead_letter_queue
  kms_master_key_id = var.kms_master_key_id != null ? var.kms_master_key_id : try(aws_kms_key.sqs[0].arn, null)

  tags = merge(var.tags, {
    Name = var.dead_letter_queue
  })
}

# Redrive Policy for each queue (pointing to DLQ)
resource "aws_sqs_queue_redrive_policy" "this" {
  for_each = var.dead_letter_queue != null ? aws_sqs_queue.this : {}

  queue_url = each.value.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  })
}

# Queue Policy (optional - for cross-account access)
resource "aws_sqs_queue_policy" "this" {
  for_each = length(var.queue_policies) > 0 ? var.queue_policies : {}

  queue_url = aws_sqs_queue.this[each.key].id
  policy    = each.value
}
