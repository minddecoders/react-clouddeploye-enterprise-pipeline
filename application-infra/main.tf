# ==========================================
# PHASE 1: TARGET CLOUD PROVIDER PLUGINS
# ==========================================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 💾 FIXED BACKEND: Cleanly separated lines to guarantee S3 state tracking syncs!
  backend "s3" {
    bucket       = "sidra-react-pipeline-vault-2026"
    key          = "react-storefrontpipeline/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ==========================================================
# 🆕 PHASE 1.1: WORKSPACE-SPECIFIC ENVIRONMENT CONFIGURATION
# ==========================================================

locals {

  # 🆕 EC2 INSTANCE SIZE MAP
  instance_sizes = {
    default = "t3.micro"
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }

  # 🆕 ECS TASK COUNT MAP
  ecs_task_counts = {
    default = 0
    dev     = 1
    staging = 1
    prod    = 2
  }

  # 🆕 Select EC2 size based on active workspace
  current_instance_type = lookup(
    local.instance_sizes,
    terraform.workspace,
    "t3.micro"
  )

  # 🆕 Select ECS task count based on active workspace
  current_ecs_scale = lookup(
    local.ecs_task_counts,
    terraform.workspace,
    0
  )
}

# ==========================================
# PHASE 2: STRUCTURAL NETWORK ARCHITECTURE
# ==========================================

resource "aws_vpc" "react_clouddeploye_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "react-clouddeploye-${terraform.workspace}-vpc"
  }
}

resource "aws_internet_gateway" "react_clouddeploye_igw" {
  vpc_id = aws_vpc.react_clouddeploye_vpc.id
}

resource "aws_route_table" "react_clouddeploye_public_rt" {
  vpc_id = aws_vpc.react_clouddeploye_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.react_clouddeploye_igw.id
  }
}

resource "aws_subnet" "react_clouddeploye_public_subnet" {
  vpc_id            = aws_vpc.react_clouddeploye_vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "react-clouddeploye-public-subnet-1a"
  }
}

resource "aws_route_table_association" "react_clouddeploye_public_assoc" {
  subnet_id      = aws_subnet.react_clouddeploye_public_subnet.id
  route_table_id = aws_route_table.react_clouddeploye_public_rt.id
}

# 🛡️ ALB has to have two public subnets
resource "aws_subnet" "react_clouddeploye_public_subnet_b" {
  vpc_id            = aws_vpc.react_clouddeploye_vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "react-clouddeploye-public-subnet-1b"
  }
}

# 🛡️ ALB
resource "aws_route_table_association" "react_clouddeploye_public_b_assoc" {
  subnet_id      = aws_subnet.react_clouddeploye_public_subnet_b.id
  route_table_id = aws_route_table.react_clouddeploye_public_rt.id
}

resource "aws_security_group" "react_clouddeploye_web_sg" {
  name        = "react-clouddeploye-web-sg"
  vpc_id      = aws_vpc.react_clouddeploye_vpc.id
  description = "Isolate instances while leaving Port 22 closed to the public internet"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# PHASE 3: SECURE IAM IDENTITY MANAGEMENT
# ==========================================

resource "aws_iam_role" "react_clouddeploye_ssm_role" {
  name = "EC2-SSM-Core-Role-react-prod-cicd-2026"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "react_clouddeploye_ssm_attach" {
  role       = aws_iam_role.react_clouddeploye_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "react_clouddeploye_ssm_profile" {
  name = "EC2-SSM-Instance-Profile-react-prod-cicd-2026"
  role = aws_iam_role.react_clouddeploye_ssm_role.name
}

# ==========================================
# PHASE 4: COMPLIANT KEYLESS COMPUTE ENGINE
# ==========================================

resource "aws_instance" "react_clouddeploye_ssm_vm" {
  ami = var.public_instance_ami

  # ✨ CHANGED: Workspace controls the EC2 size
  instance_type = local.current_instance_type

  subnet_id = aws_subnet.react_clouddeploye_public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.react_clouddeploye_web_sg.id
  ]

  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.react_clouddeploye_ssm_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  tags = {
    Name      = "react-clouddeploye-${terraform.workspace}-ssm-terraform-demo"
    ManagedBy = "Terraform-IaC"
  }
}

# ==========================================================
# PHASE 5: ISOLATED PRIVATE NETWORK & SECURITY ISOLATION PROD TIER
# ==========================================================

resource "aws_subnet" "react_clouddeploye_private_subnet" {
  vpc_id            = aws_vpc.react_clouddeploye_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "react-clouddeploye-private-1b"
  }
}

resource "aws_route_table" "react_clouddeploye_private_rt" {
  vpc_id = aws_vpc.react_clouddeploye_vpc.id

  tags = {
    Name        = "react-clouddeploye-private-rt"
    Environment = "Production"
  }
}

resource "aws_route_table_association" "react_clouddeploye_private_assoc" {
  subnet_id      = aws_subnet.react_clouddeploye_private_subnet.id
  route_table_id = aws_route_table.react_clouddeploye_private_rt.id
}

resource "aws_security_group" "react_clouddeploye_private_db_sg" {
  name        = "react-clouddeploye-private-db-sg"
  description = "Block all public access and whitelist internal database traffic queries only"
  vpc_id      = aws_vpc.react_clouddeploye_vpc.id

  ingress {
    description     = "Allow internal database queries exclusively from the front-end web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.react_clouddeploye_web_sg.id]
  }

  ingress {
    description     = "Allow internal management traffic from the public web host"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.react_clouddeploye_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "react-clouddeploye-private-db-sg"
    Environment = "Production"
  }
}

resource "aws_instance" "react_clouddeploye_private_vm" {
  ami = var.private_instance_ami

  # ✨ CHANGED: Workspace controls the private EC2 size
  instance_type = local.current_instance_type

  subnet_id = aws_subnet.react_clouddeploye_private_subnet.id

  vpc_security_group_ids = [
    aws_security_group.react_clouddeploye_private_db_sg.id
  ]

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.react_clouddeploye_ssm_profile.name

  tags = {
    Name      = "react-clouddeploye-ssm-private-backend"
    ManagedBy = "Terraform-IaC"
  }
}

# ==========================================================
# 🐳 ECS
# PHASE 6: SERVERLESS CONTAINER ORCHESTRATION (ECS & FARGATE)
# ==========================================================

# ⭐ CloudWatch
# ADDITION 1: Dedicated Cloud Storage Vault Room for System Connection Logs

resource "aws_cloudwatch_log_group" "react_clouddeploye_ecs_log_group" {
  name              = "/ecs/react-social-link-app-production-logs"
  retention_in_days = 7

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_ecs_cluster" "react_social_link_cluster" {
  name = "react-social-link-app-cluster"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_iam_role" "react_social_link_ecs_task_execution_role" {
  name = "react-social-link-app-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_iam_role_policy_attachment" "react_social_link_ecs_task_execution" {
  role       = aws_iam_role.react_social_link_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "react_social_link_task" {
  family                   = "react-social-link-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.react_social_link_ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "react-social-link-app"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # ⭐ CloudWatch
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.react_clouddeploye_ecs_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

resource "aws_ecs_service" "react_social_link_service" {
  name            = "react-social-link-app-service"
  cluster         = aws_ecs_cluster.react_social_link_cluster.id
  task_definition = aws_ecs_task_definition.react_social_link_task.arn

  # ✨✨✨ Workspace controls ECS task count
  desired_count = local.current_ecs_scale

  launch_type = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.react_clouddeploye_public_subnet.id,
      aws_subnet.react_clouddeploye_public_subnet_b.id
    ]

    security_groups = [
      aws_security_group.react_clouddeploye_web_sg.id
    ]

    assign_public_ip = true
  }

  # 🛡️ ALB
  load_balancer {
    target_group_arn = aws_lb_target_group.react_social_link_ecs_tg.arn
    container_name   = "react-social-link-app"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.react_social_link_ecs_task_execution,
    aws_lb_listener.react_social_link_http_listener
  ]
}

# ==========================================================
# 🛡️ ALB
# PHASE 7: ENTERPRISE HIGH-AVAILABILITY APPLICATION LOAD BALANCER
# ==========================================================

# 1. Public External Application Load Balancer Router

resource "aws_lb" "react_social_link_alb" {
  name               = "react-social-link-app-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.react_clouddeploye_web_sg.id
  ]

  # 💥 FIXED DUAL PUBLIC INGRESS HOOKS
  subnets = [
    aws_subnet.react_clouddeploye_public_subnet.id,
    aws_subnet.react_clouddeploye_public_subnet_b.id
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

# 2. ALB Target Group Routing Vault Bucket Container

resource "aws_lb_target_group" "react_social_link_ecs_tg" {
  name = "react-social-link-app-tg"

  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.react_clouddeploye_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform-IaC"
  }
}

# 3. ALB Listener Gatekeeper Entry Process

resource "aws_lb_listener" "react_social_link_http_listener" {
  load_balancer_arn = aws_lb.react_social_link_alb.arn

  port     = "80"
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.react_social_link_ecs_tg.arn
  }
}