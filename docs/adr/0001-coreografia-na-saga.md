# 1. Saga do pedido por coreografia

**Status:** aceito · 2026-11-17

## Contexto
O checkout envolve Ordering, Inventory, Payment, Fulfillment e Notification. A saga pode ser
orquestrada (o Ordering comanda os passos) ou coreografada (cada contexto reage aos fatos dos outros).

## Decisão
Coreografia. Nenhum serviço envia comandos; cada um publica fatos no próprio tópico e assina o que
precisa. O Ordering é dono do estado do pedido, mas não chama ninguém.

## Consequências
- Contextos independentes: adicionar o Notification não mudou nenhum outro serviço.
- O fluxo fica distribuído e difícil de enxergar. Por isso `correlationid`/`causationid` em todo evento,
  o observer do BFF e o Event Inspector do SPA são parte da solução, não extras.
- Com mais passos ou regras de compensação complexas, orquestração (ou um process manager no Ordering)
  passa a valer a pena.
