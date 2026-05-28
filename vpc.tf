# =============================================================================
# VPC Configuration — Cost-Optimized (No NAT Gateway)
# =============================================================================
#
# This module creates a VPC with PUBLIC subnets only. Fargate tasks run in
# public subnets with public IPs assigned, eliminating the ~$32/month/AZ cost
# of NAT Gateways. Security is enforced via security groups instead.
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: Available AZs
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# -----------------------------------------------------------------------------
# Public Subnets (2 AZs)
#
# cidrsubnet("10.0.0.0/16", 8, 0) → 10.0.0.0/24
# cidrsubnet("10.0.0.0/16", 8, 1) → 10.0.1.0/24
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# -----------------------------------------------------------------------------
# Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# -----------------------------------------------------------------------------
# Public Route Table — single table shared by both public subnets
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route to the Internet via the IGW
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# =============================================================================
# Security Groups
# =============================================================================

# -----------------------------------------------------------------------------
# 1. ALB Security Group
#    Allows inbound HTTP (80) and HTTPS (443) from anywhere.
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow inbound HTTP/HTTPS traffic to the ALB"
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

  # Outbound: Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# -----------------------------------------------------------------------------
# 2. ECS Security Group
#    Allows inbound ONLY from the ALB on application ports (8080, 8082, 8001).
#    No direct internet ingress — all traffic must pass through the ALB.
# -----------------------------------------------------------------------------
resource "aws_security_group" "ecs_sg" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Inbound: Port 8080 from ALB
  ingress {
    description     = "App traffic on 8080 from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound: Port 8082 from ALB
  ingress {
    description     = "App traffic on 8082 from ALB"
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Inbound: Port 8001 from ALB
  ingress {
    description     = "App traffic on 8001 from ALB"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Outbound: Allow all (needed for pulling images, reaching AWS APIs, etc.)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

# -----------------------------------------------------------------------------
# 3. EFS Security Group
#    Allows inbound NFS (2049) from ECS tasks only.
# -----------------------------------------------------------------------------
resource "aws_security_group" "efs_sg" {
  name        = "${local.name_prefix}-efs-sg"
  description = "Allow NFS access from ECS tasks to EFS"
  vpc_id      = aws_vpc.main.id

  # Inbound: NFS from ECS tasks
  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  # Outbound: Allow all
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-efs-sg"
  }
}
