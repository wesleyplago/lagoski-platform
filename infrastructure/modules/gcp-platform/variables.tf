variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "prefix" {
  type = string
}

variable "subnet_cidr" {
  type    = string
  default = "10.50.0.0/20"
}

variable "topics" {
  type = list(string)
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}

variable "github_owner" {
  type = string
}

variable "deploy_repositories" {
  type = list(string)
}

variable "state_bucket" {
  type = string
}

variable "labels" {
  type    = map(string)
  default = {}
}
