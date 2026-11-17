# Configuração parcial: bucket/key/region via -backend-config (ver backend.hcl.example).
terraform {
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
