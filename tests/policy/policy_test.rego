package terraform_mcp_eks

import future.keywords

eks_encryption_input := {
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

test_eks_encryption_pass if {
	count(deny with input as eks_encryption_input) == 0
}

eks_no_encryption_input := {
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

test_eks_encryption_fail if {
	"EKS cluster 'mcp-prod' must have encryption_config enabled" in deny with input as eks_no_encryption_input
}

prod_public_endpoint_input := {
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

test_prod_eks_public_endpoint_fail if {
	"Production EKS cluster 'mcp-prod' must not have public endpoint access enabled" in deny with input as prod_public_endpoint_input
}

elasticache_encrypted_input := {
	"resource_type": "aws_elasticache_replication_group",
	"name": "mcp-redis",
	"values": {
		"engine": "redis",
		"at_rest_encryption_enabled": true,
		"transit_encryption_enabled": true,
	},
}

test_elasticache_encryption_pass if {
	count(deny with input as elasticache_encrypted_input) == 0
}

elasticache_no_transit_input := {
	"resource_type": "aws_elasticache_replication_group",
	"name": "mcp-redis",
	"values": {
		"engine": "redis",
		"at_rest_encryption_enabled": true,
		"transit_encryption_enabled": false,
	},
}

test_elasticache_encryption_fail if {
	"ElastiCache replication group 'mcp-redis' must have transit_encryption_enabled" in deny with input as elasticache_no_transit_input
}

sqs_kms_input := {
	"resource_type": "aws_sqs_queue",
	"name": "mcp-tasks",
	"values": {
		"kms_master_key_id": "arn:aws:kms:us-west-2:123456789012:key/example",
	},
}

test_sqs_kms_pass if {
	count(deny with input as sqs_kms_input) == 0
}

sqs_no_kms_input := {
	"resource_type": "aws_sqs_queue",
	"name": "mcp-tasks",
	"values": {},
}

test_sqs_kms_fail if {
	"SQS queue 'mcp-tasks' must have kms_master_key_id configured" in deny with input as sqs_no_kms_input
}

secret_kms_input := {
	"resource_type": "aws_secretsmanager_secret",
	"name": "mcp-api-key",
	"values": {
		"kms_key_id": "alias/aws/secretsmanager",
	},
}

test_secret_kms_pass if {
	count(deny with input as secret_kms_input) == 0
}

secret_no_kms_input := {
	"resource_type": "aws_secretsmanager_secret",
	"name": "mcp-api-key",
	"values": {},
}

test_secret_kms_fail if {
	"Secrets Manager secret 'mcp-api-key' should have a kms_key_id configured" in deny with input as secret_no_kms_input
}

iam_oidc_input := {
	"resource_type": "aws_iam_role",
	"name": "mcp-server-role",
	"values": {
		"assume_role_policy": "{\"Principal\":{\"Federated\":\"arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/example\"}}",
	},
}

test_iam_oidc_pass if {
	count(deny with input as iam_oidc_input) == 0
}

iam_no_oidc_input := {
	"resource_type": "aws_iam_role",
	"name": "mcp-server-role",
	"values": {
		"assume_role_policy": "{\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}",
	},
}

test_iam_oidc_fail if {
	"IAM role 'mcp-server-role' must have an OIDC provider in the trust policy for IRSA" in deny with input as iam_no_oidc_input
}

scaled_object_input := {
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

test_scaled_object_pass if {
	count(deny with input as scaled_object_input) == 0
}

scaled_object_no_max_input := {
	"resource_type": "kubernetes_manifest",
	"name": "mcp-server-scaler",
	"values": {
		"kind": "ScaledObject",
		"spec": {
			"minReplicaCount": 0,
		},
	},
}

test_scaled_object_fail if {
	"KEDA ScaledObject 'mcp-server-scaler' must have maxReplicaCount defined" in deny with input as scaled_object_no_max_input
}
