# 2. Um tópico por bounded context, com filtro por tipo

**Status:** aceito · 2026-11-17

## Decisão
Cada contexto publica em `<contexto>.events` (Open Host Service). Cada consumidor tem a própria
assinatura com filtro pelo atributo `ce_type` (SNS filter policy / filtro do Pub/Sub) e a própria fila.

## Alternativas
- Um tópico por tipo de evento: 18 tópicos, mais IAM e mais Terraform, sem ganho para este volume.
- Um barramento único: perde a fronteira de propriedade e a permissão de publicação por contexto.

## Consequências
- Publicação restrita por IAM: cada serviço só publica no próprio tópico.
- Falha ou lentidão de um consumidor não afeta os outros (filas separadas).
- No Pub/Sub o filtro é imutável: mudar a lista de tipos recria a assinatura (mensagens pendentes
  são perdidas). Mudanças de filtro devem ser feitas com o consumidor em dia.
