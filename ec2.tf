# =============================================================================
# EC2 Instance — Docker Compose Host (ARM Graviton)
# =============================================================================
# Single t4g.small ARM instance running all 4 containers via Docker Compose.
# This is the most cost-effective approach for always-on microservices:
# - t4g.small (2 vCPU / 2 GB) ~$12/mo vs Fargate ~$40+/mo for 4 tasks
# - No NAT Gateway needed (public subnets) saves $32/mo/AZ
# - No ALB needed (nginx handles routing) saves $22/mo
#
# Total infrastructure cost: ~$13-15/month
# =============================================================================

# ---------------------------------------------------------------------------
# IAM Role — Allows EC2 to pull from ECR and write CloudWatch logs
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-ec2-role"
  }
}

# Attach AWS-managed policies
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Additional inline policy for DynamoDB access (calendar service)
# and other AWS service calls the containers may need
resource "aws_iam_role_policy" "ec2_app" {
  name = "${local.name_prefix}-ec2-app-policy"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          aws_dynamodb_table.series.arn,
          aws_dynamodb_table.polling_config.arn,
          aws_dynamodb_table.manual_event.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
        ]
        Resource = [aws_efs_file_system.backend.arn]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------------------------------------------------------
# EC2 Security Group
# ---------------------------------------------------------------------------
# Allows HTTP (80), HTTPS (443), and SSH (22) from defined CIDR ranges.
# SSH should be restricted to your IP in production.
resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "AquaOS EC2 instance — HTTP, HTTPS, SSH"
  vpc_id      = aws_vpc.main.id

  # Inbound: HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound: SSH (restrict to your IP in production)
  ingress {
    description = "SSH — restrict this in production"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  # Outbound: Allow all (needed for ECR pulls, apt updates, etc.)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

# ---------------------------------------------------------------------------
# Elastic IP — static public IP, free while attached to a running instance
# ---------------------------------------------------------------------------
resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-eip"
  }
}

# ---------------------------------------------------------------------------
# EC2 Instance — ARM Graviton (t4g.small)
# ---------------------------------------------------------------------------
# Uses the latest Amazon Linux 2023 ARM AMI.
# User data installs Docker, pulls images from ECR, and runs Docker Compose.
resource "aws_instance" "app" {
  ami           = data.aws_ssm_parameter.al2023_arm.value
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id,
    # Also allow EFS NFS traffic between this instance and EFS
    aws_security_group.efs_sg.id,
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name             = var.ssh_key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true

    tags = {
      Name = "${local.name_prefix}-root"
    }
  }

  # Attach EFS for SQLite persistence (Go backend database)
  # The user-data script mounts this at /mnt/efs/backend

  user_data = base64encode(templatefile("${path.module}/user-data.sh.tftpl", {
    aws_region        = var.aws_region
    ecr_backend_url   = aws_ecr_repository.backend.repository_url
    ecr_crew_url      = aws_ecr_repository.crew.repository_url
    ecr_web_url       = aws_ecr_repository.web.repository_url
    ecr_calendar_url  = aws_ecr_repository.calendar.repository_url
    efs_id            = aws_efs_file_system.backend.id
    jwt_key           = var.jwt_key
    admin_username    = var.admin_username
    admin_password    = var.admin_password
    openrouter_api_key = var.openrouter_api_key
    gemini_api_key    = var.gemini_api_key
    telegram_bot_token = var.telegram_bot_token
    telegram_channel_id = var.telegram_channel_id
  }))

  metadata_options {
    http_tokens   = "required"  # IMDSv2 only — prevents SSRF
    http_endpoint = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-app"
  }
}

# ---------------------------------------------------------------------------
# SSM Parameter — Latest Amazon Linux 2023 ARM AMI
# ---------------------------------------------------------------------------
data "aws_ssm_parameter" "al2023_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}
