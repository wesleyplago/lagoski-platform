# 4. Transactional Outbox e Idempotent Consumer (inbox)

**Status:** aceito · 2026-11-17

## Decisão
- **Outbox:** o evento é gravado na tabela `outbox` na mesma transação do agregado. Um relay publica
  (`for update skip locked`) e marca `published_at`.
- **Inbox:** cada evento consumido é registrado em `inbox (consumer, event_id)` na mesma transação do
  efeito. Duplicata = sem efeito.

## Consequências
- Sem dual-write: nunca há estado salvo sem evento, nem evento de estado que não foi salvo.
- Entrega é at-least-once nas duas nuvens; idempotência é obrigação do consumidor.
- Webhooks do Stripe usam a mesma tabela inbox (consumidor `stripe-webhook`, id do evento do Stripe).
