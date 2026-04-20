# Security Hardening

## Capability
Deploy MCP servers on EKS with defense-in-depth security: IRSA for pod-level IAM, network isolation, encryption at rest and in transit, and least-privilege access controls.

## Security Layers

### Layer 1: Network Isolation
- Private subnets for all EKS resources
- EKS private endpoint only (no public access)
- Security groups with minimal ingress rules
- VPC endpoints for AWS services (Secrets Manager, SQS, ElastiCache)

### Layer 2: Identity (IRSA)
- Pod-level IAM roles via IRSA (no node-level permissions)
- OIDC provider trust policy with strict conditions
- Least-privilege inline policies (not managed policies)

```hcl
resource "aws_iam_role" "mcp_server" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE:aud" = "sts.amazonaws.com"
          "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE:sub" = "system:serviceaccount:mcp:mcp-server"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "mcp_server" {
  role = aws_iam_role.mcp_server.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:*:secret:mcp-*"
      },
      {
        Effect = "Allow"
        Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = "arn:aws:sqs:*:*:mcp-*"
      }
    ]
  })
}
```

### Layer 3: Secrets Management
- All credentials in Secrets Manager (never in state or code)
- KMS encryption (customer-managed or AWS-managed keys)
- Automatic rotation support
- Pod access via IRSA only

### Layer 4: Data Protection
- EKS encryption_config for etcd encryption
- ElastiCache encryption at rest and in transit
- SQS server-side encryption with KMS
- TLS for all in-transit communication

## Terraform Resources
| Resource | Purpose | Security Configuration |
|----------|---------|----------------------|
| `aws_eks_cluster` | EKS cluster | `endpoint_private_access = true`, `encryption_config` |
| `aws_iam_openid_connect_provider` | OIDC for IRSA | `client_id_list = ["sts.amazonaws.com"]` |
| `aws_iam_role` | IRSA role | Strict trust policy with OIDC conditions |
| `aws_secretsmanager_secret` | Secrets | `kms_key_id` for encryption |
| `aws_elasticache_cluster` | Redis | `at_rest_encryption_enabled`, `transit_encryption_enabled` |
| `aws_sqs_queue` | Queue | `kms_master_key_id` for SSE |

## Security Checklist
- [ ] EKS private endpoint (no public access)
- [ ] encryption_config with secrets resource
- [ ] IRSA with least-privilege inline policies
- [ ] No node-level IAM permissions
- [ ] Secrets Manager for all credentials
- [ ] KMS encryption for secrets, SQS, ElastiCache
- [ ] ElastiCache transit encryption enabled
- [ ] Security groups restrict to minimum required ports
- [ ] VPC endpoints for AWS services (no NAT for AWS APIs)
- [ ] Container images use pinned digests (not tags)

## Error Handling
- **IRSA permission denied**: Check OIDC trust policy conditions match the service account namespace/name
- **Secrets Manager access denied**: Verify IRSA role has `secretsmanager:GetSecretValue` on the specific secret ARN
- **ElastiCache connection timeout**: Ensure security group allows port 6379 from EKS node security group
- **SQS access denied**: Verify IRSA role has `sqs:ReceiveMessage` and `sqs:DeleteMessage` on the queue ARN

## References
- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [OWASP Kubernetes Security](https://owasp.org/www-project-kubernetes-security/)
