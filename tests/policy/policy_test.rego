package terraform_mcp_eks

import future.keywords

test_eks_encryption_pass if {
	d := deny with input as eks_encryption_input
	count(d) == 0
}

test_eks_encryption_fail if {
	d := deny with input as eks_no_encryption_input
	"EKS cluster 'mcp-prod' must have encryption_config enabled" in d
}

test_prod_eks_public_endpoint_fail if {
	d := deny with input as prod_public_endpoint_input
	"Production EKS cluster 'mcp-prod' must not have public endpoint access enabled" in d
}

test_elasticache_encryption_pass if {
	d := deny with input as elasticache_encrypted_input
	count(d) == 0
}

test_elasticache_encryption_fail if {
	d := deny with input as elasticache_no_transit_input
	"ElastiCache replication group 'mcp-redis' must have transit_encryption_enabled" in d
}

test_sqs_kms_pass if {
	d := deny with input as sqs_kms_input
	count(d) == 0
}

test_sqs_kms_fail if {
	d := deny with input as sqs_no_kms_input
	"SQS queue 'mcp-tasks' must have kms_master_key_id configured" in d
}

test_secret_kms_pass if {
	d := deny with input as secret_kms_input
	count(d) == 0
}

test_secret_kms_fail if {
	d := deny with input as secret_no_kms_input
	"Secrets Manager secret 'mcp-api-key' should have a kms_key_id configured" in d
}

test_iam_oidc_pass if {
	d := deny with input as iam_oidc_input
	count(d) == 0
}

test_iam_oidc_fail if {
	d := deny with input as iam_no_oidc_input
	"IAM role 'mcp-server-role' must have an OIDC provider in the trust policy for IRSA" in d
}

test_scaled_object_pass if {
	d := deny with input as scaled_object_input
	count(d) == 0
}

test_scaled_object_fail if {
	d := deny with input as scaled_object_no_max_input
	"KEDA ScaledObject 'mcp-server-scaler' must have maxReplicaCount defined" in d
}

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

elasticache_encrypted_input := {
	"resource_type": "aws_elasticache_replication_group",
	"name": "mcp-redis",
	"values": {
		"engine": "redis",
		"at_rest_encryption_enabled": true,
		"transit_encryption_enabled": true,
	},
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

sqs_kms_input := {
	"resource_type": "aws_sqs_queue",
	"name": "mcp-tasks",
	"values": {
		"kms_master_key_id": "arn:aws:kms:us-west-2:123456789012:key/example",
	},
}

sqs_no_kms_input := {
	"resource_type": "aws_sqs_queue",
	"name": "mcp-tasks",
	"values": {},
}

secret_kms_input := {
	"resource_type": "aws_secretsmanager_secret",
	"name": "mcp-api-key",
	"values": {
		"kms_key_id": "alias/aws/secretsmanager",
	},
}

secret_no_kms_input := {
	"resource_type": "aws_secretsmanager_secret",
	"name": "mcp-api-key",
	"values": {},
}

iam_oidc_input := {
	"resource_type": "aws_iam_role",
	"name": "mcp-server-role",
	"values": {
		"assume_role_policy": "{\"Principal\":{\"Federated\":\"arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/example\"}}",
	},
}

iam_no_oidc_input := {
	"resource_type": "aws_iam_role",
	"name": "mcp-server-role",
	"values": {
		"assume_role_policy": "{\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}",
	},
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
