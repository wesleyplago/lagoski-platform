variable "prefix" {
  description = "Prefixo de todos os recursos (ex.: lagoski-dev)."
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "topics" {
  description = "Catálogo de tópicos (Published Language). Um por bounded context que publica."
  type        = list(string)
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "certificate_arn" {
  description = "Certificado ACM para HTTPS no ALB. null = só HTTP (demo)."
  type        = string
  default     = null
}

variable "github_owner" {
  type = string
}

variable "deploy_repositories" {
  description = "Repositórios que podem assumir o papel de deploy via OIDC (ambiente GitHub aws-<env>)."
  type        = list(string)
}

variable "github_environment" {
  type    = string
  default = "aws-dev"
}

variable "state_bucket" {
  description = "Bucket do state, para os pipelines lerem/escreverem."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
