# 8. Uma instância de Postgres, um database por serviço

**Status:** aceito · 2026-11-17

## Decisão
Uma instância (RDS / Cloud SQL) para reduzir custo da demo. Cada serviço tem database e usuário
próprios, sem acesso aos dos outros. Na AWS, um init container do serviço cria role e database com a
credencial de admin da plataforma; no GCP, o Terraform do serviço cria via API do Cloud SQL.

## Consequências
Isolamento lógico preservado (database per service). Em produção, serviços críticos teriam
instâncias próprias; a troca é só de variável no Terraform.
