package terraform_mcp_eks

deny[msg] {
  input.resource_type == "aws_eks_cluster"
  not input.values.encryption_config
  msg := sprintf("EKS cluster '%s' must have encryption_config enabled", [input.name])
}

deny[msg] {
  input.resource_type == "aws_eks_cluster"
  lower(object.get(object.get(input.values, "tags", {}), "Environment", "")) == "prod"
  object.get(object.get(input.values, "vpc_config", {}), "endpoint_public_access", false)
  msg := sprintf("Production EKS cluster '%s' must not have public endpoint access enabled", [input.name])
}

deny[msg] {
  input.resource_type == "aws_elasticache_replication_group"
  input.values.engine == "redis"
  not input.values.at_rest_encryption_enabled
  msg := sprintf("ElastiCache replication group '%s' must have at_rest_encryption_enabled", [input.name])
}

deny[msg] {
  input.resource_type == "aws_elasticache_replication_group"
  input.values.engine == "redis"
  not input.values.transit_encryption_enabled
  msg := sprintf("ElastiCache replication group '%s' must have transit_encryption_enabled", [input.name])
}

deny[msg] {
  input.resource_type == "aws_sqs_queue"
  not input.values.kms_master_key_id
  msg := sprintf("SQS queue '%s' must have kms_master_key_id configured", [input.name])
}

deny[msg] {
  input.resource_type == "aws_secretsmanager_secret"
  not input.values.kms_key_id
  msg := sprintf("Secrets Manager secret '%s' should have a kms_key_id configured", [input.name])
}

deny[msg] {
  input.resource_type == "aws_iam_role"
  startswith(input.name, "mcp-")
  not contains(input.values.assume_role_policy, "oidc.eks")
  msg := sprintf("IAM role '%s' must have an OIDC provider in the trust policy for IRSA", [input.name])
}

deny[msg] {
  input.resource_type == "kubernetes_manifest"
  input.values.kind == "ScaledObject"
  not input.values.spec.minReplicaCount
  msg := sprintf("KEDA ScaledObject '%s' must have minReplicaCount defined", [input.name])
}

deny[msg] {
  input.resource_type == "kubernetes_manifest"
  input.values.kind == "ScaledObject"
  not input.values.spec.maxReplicaCount
  msg := sprintf("KEDA ScaledObject '%s' must have maxReplicaCount defined", [input.name])
}
