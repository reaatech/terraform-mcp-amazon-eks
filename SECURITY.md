# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of terraform-mcp-aws-eks seriously. If you believe you have found a security vulnerability, please report it to us as described below.

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to security@your-org.com with the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

## Security Best Practices

When using this module, please follow these security best practices:

### 1. Secrets Management
- Never store secrets in Terraform state or variables
- Use Secrets Manager for all sensitive values
- Rotate secrets regularly
- Use KMS encryption for secrets

### 2. IAM and IRSA
- Follow the principle of least privilege
- Use IRSA for pod-level IAM, not node-level
- Never use access keys in code
- Regularly audit IAM roles and policies

### 3. Network Security
- Use private subnets for all EKS resources
- Restrict security group ingress to required ports only
- Use VPC endpoints for AWS services
- Enable EKS private endpoint

### 4. Infrastructure
- Enable EKS encryption_config for etcd encryption
- Enable encryption at rest for ElastiCache
- Enable encryption in transit for ElastiCache
- Use Multi-AZ for production ElastiCache
- Enable CloudWatch logging for EKS

### 5. Container Security
- Use image digests instead of tags in production
- Scan images for vulnerabilities
- Use read-only root filesystem where possible
- Run containers as non-root users

### 6. Monitoring
- Enable CloudTrail for API auditing
- Configure CloudWatch alarms for security events
- Enable X-Ray for distributed tracing
- Monitor access patterns and anomalies

## Known Limitations

1. **Terraform State**: Ensure your remote state backend (S3) is properly secured with appropriate access controls and encryption.

2. **Container Images**: Always use pinned container image digests in production to prevent supply chain attacks.

3. **IRSA**: IRSA requires proper OIDC provider configuration. Ensure your EKS cluster's OIDC provider is correctly set up.

## Security Updates

Security updates will be released as patch versions. Critical security fixes may result in immediate releases.

Subscribe to our release notifications to stay informed about security updates.

## References

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [Terraform Security Best Practices](https://developer.hashicorp.com/terraform/tutorials/configuration-language/security)
- [OWASP Kubernetes Security](https://owasp.org/www-project-kubernetes-security/)
