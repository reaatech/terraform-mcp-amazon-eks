data "aws_vpc" "default" {
  count   = var.vpc_id == null && var.subnet_ids == null ? 1 : 0
  default = true
}

data "aws_subnets" "selected_vpc" {
  count = var.subnet_ids == null && var.vpc_id != null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "default_vpc" {
  count = var.subnet_ids == null && var.vpc_id == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

data "aws_caller_identity" "current" {}

locals {
  selected_subnet_ids = var.subnet_ids != null ? var.subnet_ids : (
    var.vpc_id != null ? data.aws_subnets.selected_vpc[0].ids : data.aws_subnets.default_vpc[0].ids
  )

  default_sqs_queues = {
    "${var.cluster_name}-tasks" = {
      visibility_timeout_seconds = 60
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
    "${var.cluster_name}-results" = {
      visibility_timeout_seconds = 120
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 20
    }
  }

  sqs_queues = length(var.sqs_queues) > 0 ? var.sqs_queues : local.default_sqs_queues

  task_queue_name = var.task_queue_name != null ? var.task_queue_name : (
    contains(keys(local.sqs_queues), "${var.cluster_name}-tasks") ? "${var.cluster_name}-tasks" : sort(keys(local.sqs_queues))[0]
  )
  dlq_name = var.dead_letter_queue_name != null ? var.dead_letter_queue_name : "${var.cluster_name}-dlq"

  default_secret_definitions = var.create_api_key_secret ? {
    api-key = {
      secret_id   = "${var.cluster_name}-api-key"
      description = "API key for the MCP service"
      kms_key_id  = null
    }
  } : {}

  effective_secrets = merge(local.default_secret_definitions, var.secrets)

  default_secret_values = var.create_api_key_secret && var.api_key_value != null ? {
    api-key = jsonencode({
      api_key = var.api_key_value
    })
  } : {}

  effective_secret_values = merge(local.default_secret_values, var.secret_values)

  default_tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "terraform-mcp-aws-eks"
  }, var.tags)

  secret_arn_patterns = [
    for secret in values(local.effective_secrets) :
    "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${secret.secret_id}*"
  ]

  service_inline_policies = merge(
    {
      sqs = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "sqs:ChangeMessageVisibility",
              "sqs:DeleteMessage",
              "sqs:GetQueueAttributes",
              "sqs:GetQueueUrl",
              "sqs:ReceiveMessage",
              "sqs:SendMessage"
            ]
            Resource = concat(
              values(module.sqs.queue_arns),
              compact([module.sqs.dlq_arn])
            )
          }
        ]
      })
    },
    length(local.secret_arn_patterns) > 0 ? {
      secrets = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "secretsmanager:DescribeSecret",
              "secretsmanager:GetSecretValue"
            ]
            Resource = local.secret_arn_patterns
          }
        ]
      })
    } : {}
  )
}

module "eks" {
  source = "./modules/eks"

  cluster_name               = var.cluster_name
  subnet_ids                 = local.selected_subnet_ids
  node_groups                = var.node_groups
  kubernetes_version         = var.kubernetes_version
  cluster_security_group_ids = var.cluster_security_group_ids
  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  enable_encryption          = var.enable_cluster_encryption
  kms_key_id                 = var.cluster_kms_key_id
  tags                       = local.default_tags
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}

module "sqs" {
  source = "./modules/sqs"

  queues            = local.sqs_queues
  dead_letter_queue = local.dlq_name
  kms_master_key_id = var.sqs_kms_master_key_id
  max_receive_count = var.max_receive_count
  queue_policies    = var.queue_policies
  tags              = local.default_tags
}

module "elasticache" {
  source = "./modules/elasticache"

  cluster_id                 = "${var.cluster_name}-redis"
  node_type                  = var.elasticache_node_type
  num_cache_nodes            = var.elasticache_num_nodes
  engine_version             = var.elasticache_engine_version
  subnet_ids                 = local.selected_subnet_ids
  security_group_ids         = [module.eks.cluster_security_group_id]
  parameter_group_name       = var.elasticache_parameter_group_name
  snapshot_retention_days    = var.elasticache_snapshot_retention_days
  maintenance_window         = var.elasticache_maintenance_window
  notification_topic_arn     = var.elasticache_notification_topic_arn
  at_rest_encryption_enabled = var.elasticache_at_rest_encryption_enabled
  transit_encryption_enabled = var.elasticache_transit_encryption_enabled
  multi_az_enabled           = var.elasticache_multi_az_enabled
  auth_token                 = var.elasticache_auth_token
  tags                       = local.default_tags
}

module "iam" {
  source = "./modules/iam"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  service_accounts = {
    (var.service_account_name) = {
      namespace       = var.namespace
      policies        = var.managed_policy_arns
      inline_policies = local.service_inline_policies
    }
  }

  tags = local.default_tags
}

module "secrets" {
  source = "./modules/secrets"

  secrets                 = local.effective_secrets
  secret_values           = local.effective_secret_values
  access_roles            = [module.iam.role_arns[var.service_account_name]]
  recovery_window_in_days = var.secret_recovery_window_in_days
  tags                    = local.default_tags
}

module "keda" {
  count  = var.enable_keda ? 1 : 0
  source = "./modules/keda"

  release_name     = var.keda_release_name
  namespace        = var.keda_namespace
  create_namespace = true
  chart_version    = var.keda_chart_version
  values           = var.keda_values

  providers = {
    helm = helm
  }
}

module "mcp_service" {
  source = "./modules/mcp-service"

  namespace               = var.namespace
  deployment_name         = var.deployment_name
  region                  = var.region
  image                   = var.mcp_server_image
  service_account_name    = var.service_account_name
  iam_role_arn            = module.iam.role_arns[var.service_account_name]
  min_replicas            = var.min_replicas
  max_replicas            = var.max_replicas
  warm_pool_size          = var.warm_pool_size
  scale_up_threshold      = var.scale_up_threshold
  activation_queue_length = var.activation_queue_length
  scale_down_delay        = var.scale_down_delay
  sqs_queue_url           = module.sqs.queue_urls[local.task_queue_name]
  scale_on_in_flight      = var.scale_on_in_flight
  scale_on_delayed        = var.scale_on_delayed
  cpu_request             = var.cpu_request
  memory_request          = var.memory_request
  cpu_limit               = var.cpu_limit
  memory_limit            = var.memory_limit
  env_vars = merge({
    AWS_REGION             = var.region
    REDIS_ENDPOINT         = module.elasticache.cluster_address
    MCP_TASK_QUEUE_URL     = module.sqs.queue_urls[local.task_queue_name]
    MCP_RESULTS_QUEUE_URL  = try(module.sqs.queue_urls["${var.cluster_name}-results"], "")
    MCP_API_KEY_SECRET_ARN = try(module.secrets.secret_arns["api-key"], "")
  }, var.env_vars)
  kubernetes_secret_env_vars = var.kubernetes_secret_env_vars
  create_namespace           = true
  enable_hpa                 = var.enable_hpa
  enable_keda_scaling        = var.enable_keda_scaling
  target_cpu_utilization     = var.target_cpu_utilization
  target_memory_utilization  = var.target_memory_utilization
  node_selector              = var.node_selector
  tolerations                = var.tolerations
  service_type               = var.service_type

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    module.eks,
    module.keda
  ]
}

module "monitoring" {
  source = "./modules/monitoring"

  cluster_name                       = var.cluster_name
  alert_email                        = var.alert_email
  xray_enabled                       = var.xray_enabled
  sqs_queue_names                    = keys(local.sqs_queues)
  elasticache_cluster_id             = "${var.cluster_name}-redis"
  enable_alarms                      = var.enable_alarms
  sqs_depth_alarm_threshold          = var.sqs_depth_alarm_threshold
  elasticache_cpu_alarm_threshold    = var.elasticache_cpu_alarm_threshold
  elasticache_memory_alarm_threshold = var.elasticache_memory_alarm_threshold
  tags                               = local.default_tags
}
