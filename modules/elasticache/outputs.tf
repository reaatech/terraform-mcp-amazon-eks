output "cluster_address" {
  description = "Primary ElastiCache endpoint address"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "cluster_port" {
  description = "ElastiCache cluster port"
  value       = aws_elasticache_replication_group.this.port
}

output "cluster_endpoint" {
  description = "Full ElastiCache cluster endpoint (address:port)"
  value       = "${aws_elasticache_replication_group.this.primary_endpoint_address}:${aws_elasticache_replication_group.this.port}"
}

output "cluster_arn" {
  description = "ARN of the ElastiCache cluster"
  value       = aws_elasticache_replication_group.this.arn
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Name of the ElastiCache parameter group"
  value       = var.parameter_group_name != "" ? var.parameter_group_name : aws_elasticache_parameter_group.this[0].name
}

output "reader_endpoint_address" {
  description = "Reader endpoint for the ElastiCache replication group"
  value       = try(aws_elasticache_replication_group.this.reader_endpoint_address, null)
}
