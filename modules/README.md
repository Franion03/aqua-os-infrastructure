# Modules

Future refactoring should split the root configuration into reusable modules:

- **modules/networking** — VPC, subnets, internet gateway, route tables (from `vpc.tf`)
- **modules/compute** — EC2 instances, security groups, key pairs (from `ec2.tf`)
- **modules/storage** — EFS, ECR, DynamoDB (from `efs.tf`, `ecr.tf`, `dynamodb.tf`)
