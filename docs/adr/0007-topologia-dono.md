# 7. Tópicos na plataforma, assinaturas nos serviços

**Status:** aceito · 2026-11-17

## Contexto
Cada microsserviço tem repositório e Terraform próprios. Ordering e Inventory se assinam mutuamente:
se cada produtor criasse o próprio tópico, o primeiro deploy teria dependência circular.

## Decisão
- O `lagoski-platform` cria o catálogo de tópicos (é o registro da Published Language).
- Cada serviço cria **as suas** filas, DLQs, assinaturas, filtros e permissões, a partir do
  `messaging.json` do próprio repositório, o mesmo arquivo que o código lê.
- O schema de cada evento continua sendo do contexto produtor (`lagoski-contracts`).

## Consequências
Qualquer serviço sobe em qualquer ordem depois da plataforma. Um consumidor novo não exige mudança
em nenhum outro repositório.
