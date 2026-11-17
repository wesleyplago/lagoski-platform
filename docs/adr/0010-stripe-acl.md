# 10. Stripe Checkout atrás de uma Anti-Corruption Layer

**Status:** aceito · 2026-11-17

## Decisão
O Payment integra com o **Stripe em sandbox** via Checkout Sessions (página hospedada), com:
- chave **restrita** (`rk_test_`) com escrita em Checkout Sessions e Refunds; chave live é recusada
  fora de produção;
- idempotency key por pedido na criação do checkout e por pagamento no estorno;
- webhook com assinatura verificada sobre o corpo cru, tratando `checkout.session.completed` e
  `async_payment_succeeded` (só se `payment_status` não for `unpaid`), `async_payment_failed`,
  `checkout.session.expired` e `charge.refunded`;
- métodos de pagamento dinâmicos (sem `payment_method_types`) e sem `automatic_tax`.

A porta `PaymentGateway` fala a língua do contexto; o adapter do Stripe traduz Checkout Sessions e
eventos para `paid`, `payment-failed`, `checkout-expired` e `refunded`. Nenhum tipo do SDK sai dele.

## Consequências
- O checkout expira em no mínimo 30 minutos (regra do Stripe); a reserva de estoque dura 35.
- Pagamento que chega depois do cancelamento do pedido é estornado automaticamente.
- Na nuvem, o webhook entra pelo BFF (`/api/webhooks/stripe`), que repassa os bytes intactos ao Payment.
