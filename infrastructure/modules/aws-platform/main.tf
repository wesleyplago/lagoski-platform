data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  private_subnets = [for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, 200 + i)]
  service_domain  = "lagoski.local"
}

# ------------------------------------------------------------------ rede

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16"

  name = var.prefix
  cidr = var.vpc_cidr
  azs  = var.availability_zones

  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  # Um NAT só: demo. Em produção, um por AZ ou VPC endpoints para SNS/SQS/ECR/Logs.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

# ------------------------------------------------------------- compute

resource "aws_ecs_cluster" "this" {
  name = var.prefix
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Descoberta de serviço: catalog.lagoski.local, ordering.lagoski.local...
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = local.service_domain
  description = "Serviços internos do Lagoski"
  vpc         = module.vpc.vpc_id
  tags        = var.tags
}

# ------------------------------------------------------------- borda

resource "aws_security_group" "alb" {
  name        = "${var.prefix}-alb"
  description = "ALB público do Lagoski"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count             = var.certificate_arn == null ? 0 : 1
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
}

resource "aws_lb" "this" {
  name               = var.prefix
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]
  # SSE do Event Inspector: conexões longas.
  idle_timeout               = 300
  drop_invalid_header_fields = true
  tags                       = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn == null ? "fixed-response" : "redirect"

    dynamic "fixed_response" {
      for_each = var.certificate_arn == null ? [1] : []
      content {
        content_type = "application/json"
        message_body = "{\"error\":\"NOT_FOUND\"}"
        status_code  = "404"
      }
    }

    dynamic "redirect" {
      for_each = var.certificate_arn == null ? [] : [1]
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
  tags = var.tags
}

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn == null ? 0 : 1
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"NOT_FOUND\"}"
      status_code  = "404"
    }
  }
  tags = var.tags
}

# -------------------------------------------------------------- dados

resource "aws_security_group" "db" {
  name        = "${var.prefix}-db"
  description = "Postgres compartilhado (um database e um role por serviço)"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = var.vpc_cidr
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_db_subnet_group" "this" {
  name       = var.prefix
  subnet_ids = module.vpc.private_subnets
  tags       = var.tags
}

# Uma instância para a demo (custo). O isolamento é lógico: cada serviço tem
# database e role próprios, criados pelo init container do serviço.
resource "aws_db_instance" "this" {
  identifier                  = var.prefix
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = var.db_instance_class
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  username                    = "lagoski_admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
  backup_retention_period     = 1
  skip_final_snapshot         = true
  deletion_protection         = false
  apply_immediately           = true
  tags                        = var.tags
}

# ---------------------------------------------------------- mensageria

# Catálogo de tópicos. Filas, DLQs e assinaturas são de cada serviço consumidor.
resource "aws_sns_topic" "this" {
  for_each          = toset(var.topics)
  name              = "${var.prefix}-${replace(each.value, ".", "-")}"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}
