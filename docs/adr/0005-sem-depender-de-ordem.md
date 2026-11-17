# 5. Não depender da ordem das mensagens

**Status:** aceito · 2026-11-17

## Decisão
Filas SQS Standard e Pub/Sub sem ordering key. Os agregados validam transições: um evento que não
faz sentido no estado atual é ignorado e registrado (nunca lança). Onde a ordem importa, o domínio
aceita os dois caminhos (ex.: `PaymentRequested` antes de `StockReserved` também avança o pedido).

## Consequências
Mais throughput e nada de partição quente. O custo é modelar estados de forma tolerante, coberto por
testes de domínio que simulam a chegada fora de ordem.
