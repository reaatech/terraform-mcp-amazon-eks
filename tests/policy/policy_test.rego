package terraform_mcp_eks

import future.keywords

test_eks_encryption_pass if {
  not deny with input as {
    "resource_type": "aws_eks_cluster",
    "name": "mcp-dev",
    "values": {
      "encryption_config": [{"resources": ["secrets"]}],
      "vpc_config": {
        "endpoint_public_access": true,
      },
      "tags": {
        "Environment": "dev",
      },
    },
  }
}

test_eks_encryption_fail if {
  some msg in deny
  msg == "EKS cluster 'mcp-prod' must have encryption_config enabled"
    with input as {
      "resource_type": "aws_eks_cluster",
      "name": "mcp-prod",
      "values": {
        "vpc_config": {
          "endpoint_public_access": false,
        },
        "tags": {
          "Environment": "prod",
        },
      },
    }
}

test_prod_eks_public_endpoint_fail if {
  some msg in deny
  msg == "Production EKS cluster 'mcp-prod' must not have public endpoint access enabled"
    with input as {
      "resource_type": "aws_eks_cluster",
      "name": "mcp-prod",
      "values": {
        "encryption_config": [{"resources": ["secrets"]}],
        "vpc_config": {
          "endpoint_public_access": true,
        },
        "tags": {
          "Environment": "prod",
        },
      },
    }
}

test_elasticache_encryption_pass if {
  not deny with input as {
    "resource_type": "aws_elasticache_replication_group",
    "name": "mcp-redis",
    "values": {
      "engine": "redis",
      "at_rest_encryption_enabled": true,
      "transit_encryption_enabled": true,
    },
  }
}

test_elasticache_encryption_fail if {
  some msg in deny
  msg == "ElastiCache replication group 'mcp-redis' must have transit_encryption_enabled"
    with input as {
      "resource_type": "aws_elasticache_replication_group",
      "name": "mcp-redis",
      "values": {
        "engine": "redis",
        "at_rest_encryption_enabled": true,
        "transit_encryption_enabled": false,
      },
    }
}

test_sqs_kms_pass if {
  not deny with input as {
    "resource_type": "aws_sqs_queue",
    "name": "mcp-tasks",
    "values": {
      "kms_master_key_id": "arn:aws:kms:us-west-2:123456789012:key/example",
    },
  }
}

test_sqs_kms_fail if {
  some msg in deny
  msg == "SQS queue 'mcp-tasks' must have kms_master_key_id configured"
    with input as {
      "resource_type": "aws_sqs_queue",
      "name": "mcp-tasks",
      "values": {},
    }
}

test_secret_kms_pass if {
  not deny with input as {
    "resource_type": "aws_secretsmanager_secret",
    "name": "mcp-api-key",
    "values": {
      "kms_key_id": "alias/aws/secretsmanager",
    },
  }
}

test_secret_kms_fail if {
  some msg in deny
  msg == "Secrets Manager secret 'mcp-api-key' should have a kms_key_id configured"
    with input as {
      "resource_type": "aws_secretsmanager_secret",
      "name": "mcp-api-key",
      "values": {},
    }
}

test_iam_oidc_pass if {
  not deny with input as {
    "resource_type": "aws_iam_role",
    "name": "mcp-server-role",
    "values": {
      "assume_role_policy": "{\"Principal\":{\"Federated\":\"arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/example\"}}",
    },
  }
}

test_iam_oidc_fail if {
  some msg in deny
  msg == "IAM role 'mcp-server-role' must have an OIDC provider in the trust policy for IRSA"
    with input as {
      "resource_type": "aws_iam_role",
      "name": "mcp-server-role",
      "values": {
        "assume_role_policy": "{\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}",
      },
    }
}

test_scaled_object_pass if {
  not deny with input as {
    "resource_type": "kubernetes_manifest",
    "name": "mcp-server-scaler",
    "values": {
      "kind": "ScaledObject",
      "spec": {
        "minReplicaCount": 0,
        "maxReplicaCount": 10,
      },
    },
  }
}

test_scaled_object_fail if {
  some msg in deny
  msg == "KEDA ScaledObject 'mcp-server-scaler' must have maxReplicaCount defined"
    with input as {
      "resource_type": "kubernetes_manifest",
      "name": "mcp-server-scaler",
      "values": {
        "kind": "ScaledObject",
        "spec": {
          "minReplicaCount": 0,
        },
      },
    }
}
