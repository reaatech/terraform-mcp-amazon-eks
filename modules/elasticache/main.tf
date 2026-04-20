# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  name       = var.cluster_id
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.cluster_id
  })
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "this" {
  count = var.parameter_group_name == "" ? 1 : 0

  name   = "${var.cluster_id}-pg"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = var.tags
}

# ElastiCache Redis replication group
resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = var.cluster_id
  description                = "Redis replication group for ${var.cluster_id}"
  engine                     = "redis"
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_nodes
  engine_version             = var.engine_version
  port                       = var.port
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = var.security_group_ids
  parameter_group_name       = var.parameter_group_name != "" ? var.parameter_group_name : aws_elasticache_parameter_group.this[0].name
  snapshot_retention_limit   = var.snapshot_retention_days
  maintenance_window         = var.maintenance_window != "" ? var.maintenance_window : null
  notification_topic_arn     = var.notification_topic_arn
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.multi_az_enabled || var.num_cache_nodes > 1
  auth_token                 = var.auth_token

  tags = var.tags
}
