# 6. Push no GCP, pull na AWS, mesma porta

**Status:** aceito · 2026-11-17

## Decisão
A porta `EventSubscriber` tem dois adapters: na AWS o serviço faz long polling no SQS e controla o
backoff com `ChangeMessageVisibility`; no GCP o Pub/Sub faz push para `POST /_events/pubsub` no
Cloud Run, autenticado por token OIDC. O domínio não sabe qual está em uso.

## Consequências
Cloud Run pode escalar a zero no GCP. Na AWS, o ECS mantém ao menos uma tarefa ativa por serviço.
A configuração (`MESSAGING_PROVIDER`) escolhe o adapter; a mesma imagem roda nas duas nuvens.
