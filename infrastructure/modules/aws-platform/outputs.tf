# Contrato com os repositórios de serviço: o tipo deste objeto é o da variável
# `platform` do módulo aws-service. Mudanças aqui são mudanças de contrato.
output "service_platform" {
  value = {
    vpc_id                         = module.vpc.vpc_id
    vpc_cidr                       = var.vpc_cidr
    private_subnet_ids             = module.vpc.private_subnets
    ecs_cluster_arn                = aws_ecs_cluster.this.arn
    service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.this.id
    service_discovery_domain       = local.service_domain
    alb_listener_arn               = var.certificate_arn == null ? aws_lb_listener.http.arn : aws_lb_listener.https[0].arn
    alb_security_group_id          = aws_security_group.alb.id
    db_host                        = aws_db_instance.this.address
    db_port                        = aws_db_instance.this.port
    db_admin_username              = aws_db_instance.this.username
    db_admin_secret_arn            = aws_db_instance.this.master_user_secret[0].secret_arn
    topic_arns                     = { for name, t in aws_sns_topic.this : name => t.arn }
    topic_arn_prefix               = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:"
  }
}

output "public_url" {
  description = "URL pública do BFF (ALB)."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${aws_lb.this.dns_name}"
}

output "deploy_role_arns" {
  value = { for repo, role in aws_iam_role.deploy : repo => role.arn }
}
