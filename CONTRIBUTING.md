# Contributing to terraform-mcp-aws-eks

Thank you for your interest in contributing to terraform-mcp-aws-eks! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- Terraform >= 1.6
- [TFLint](https://github.com/terraform-linters/tflint) installed
- [Go](https://golang.org/dl/) 1.21+ (for running tests)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [helm](https://helm.sh/docs/intro/install/) installed
- An AWS account with appropriate permissions (for integration tests)

### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/reaatech/terraform-mcp-aws-eks.git
   cd terraform-mcp-aws-eks
   ```
3. Create a branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### 1. Code Style

All Terraform code must be formatted using `terraform fmt`:

```bash
terraform fmt -recursive
```

### 2. Linting

Run TFLint before committing:

```bash
tflint --init  # Run once to initialize
tflint --recursive
```

### 3. Validation

Validate all modules and environments:

```bash
# Validate a specific module
terraform init -backend=false modules/eks
terraform validate modules/eks

# Validate all modules
for dir in modules/*; do
  terraform init -backend=false $dir
  terraform validate $dir
done
```

### 4. Testing

Run unit tests:

```bash
cd tests/unit
go test -v ./...
```

Run integration tests (requires AWS credentials and EKS cluster):

```bash
export AWS_PROFILE=your-profile
export AWS_REGION=us-west-2
cd tests/integration
go test -v ./...
```

Run policy checks:

```bash
conftest test modules --policy tests/policy
```

### 5. Documentation

Update documentation for any user-facing changes:

- Update README.md for module changes
- Add inline comments for complex logic
- Update examples if behavior changes
- Update DEV_PLAN.md checklist

## Pull Request Process

1. **Create a PR** with a clear title and description
2. **Link related issues** using `Fixes #123` syntax
3. **Ensure all checks pass**:
   - Terraform format check
   - TFLint
   - Terraform validate
   - Unit tests
   - Policy checks
4. **Request review** from maintainers
5. **Address feedback** and update the PR

## PR Checklist

- [ ] Code is formatted with `terraform fmt`
- [ ] TFLint passes with no errors
- [ ] Terraform validate passes for all modified modules
- [ ] Tests are added/updated for new functionality
- [ ] Documentation is updated
- [ ] DEV_PLAN.md checklist is updated (if applicable)
- [ ] Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)

## Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Types include:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(keda): add support for custom scaling metrics

Add support for custom CloudWatch metrics in KEDA scaling.
This enables more flexible auto-scaling based on application-specific metrics.

Fixes #42
```

## Module Development Guidelines

### Variable Naming
- Use snake_case for variable names
- Use descriptive names (e.g., `cluster_name` not `cname`)
- Add descriptions for all variables
- Set appropriate defaults (use `null` for required variables)

### Resource Naming
- Use consistent naming patterns
- Include the module name in resource names
- Use `count` or `for_each` for conditional resources

### Outputs
- Output all important resource attributes
- Use descriptive output names
- Add descriptions for all outputs

### Backward Compatibility
- Avoid breaking changes when possible
- If breaking changes are necessary, increment the major version
- Document migration steps in the PR description

## AWS-Specific Considerations

### IRSA Configuration
- Always use IRSA for pod-level IAM
- Never grant permissions at the node level
- Ensure OIDC provider is properly configured

### EKS Best Practices
- Use managed node groups
- Enable cluster autoscaler
- Use private subnets for all resources
- Enable control plane logging

### Cost Optimization
- Use spot instances for non-critical workloads
- Right-size node groups
- Configure appropriate warm pool sizes
- Use KEDA for scale-to-zero capability

## Reporting Bugs

Use the GitHub issue template and include:
- Terraform version
- Module version
- AWS region
- Expected behavior
- Actual behavior
- Steps to reproduce
- Relevant code snippets

## Suggesting Features

Before creating a feature request:
1. Check existing issues for similar requests
2. Consider if it fits the module's scope
3. Provide a clear use case

## Questions?

Feel free to open an issue for any questions or concerns.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
