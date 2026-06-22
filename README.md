# 🏗️ aqua-os-infrastructure

Terraform infrastructure for deploying aqua-os on AWS.

## Architecture

Provisions the full runtime environment for aqua-os microservices on a single EC2 instance with supporting AWS services.

```
main.tf           → providers, backend
vpc.tf            → VPC, subnets, IGW, routes
ec2.tf            → EC2 instance, security groups
ecr.tf            → container registries
efs.tf            → persistent storage
dynamodb.tf       → NoSQL tables
variables.tf      → input variables
outputs.tf        → exported values
user-data.sh.tftpl → EC2 bootstrap script
docker-compose.prod.yml → production compose file
```

**Resources provisioned:** VPC, EC2, ECR, EFS, DynamoDB

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions for VPC, EC2, ECR, EFS, DynamoDB

## Run Locally

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | configurable |
| See `variables.tf` for full list | | |

## Destroy

```bash
terraform destroy
```

## Related Repos

| Repo | Description |
|------|-------------|
| [aqua-os-backend](../aqua-os-backend) | Go REST API |
| [aqua-os-web](../aqua-os-web) | React frontend |
| [aqua-os-crew](../aqua-os-crew) | AI agents (CrewAI) |
| [aqua-os-calendar](../aqua-os-calendar) | Game calendar service |

## License

GPL-3.0
