# Lagoski — Especificação

Loja de camisetas que demonstra **bounded contexts (DDD)** em **microsserviços** integrados só por
**eventos** (filas + distribuição por assinatura em tópicos), rodando na **AWS e no GCP** com o mesmo
código, infraestrutura em **Terraform** por serviço e um **SPA em microfrontends** que mostra o fluxo.
O pagamento usa o **Stripe em sandbox** atrás de uma Anti-Corruption Layer.

| Item | Valor |
| --- | --- |
| Status | v0.1 · 2026-11-17 |
| Escopo | portfólio / demonstração, não produção |
| Diagramas | [arquitetura (portfólio)](https://github.com/wesleyplago/portfolio/blob/main/apps/portfolio/public/lagoski/arquitetura.html) |
| Decisões | [docs/adr](adr) |

## 1. Objetivos

1. Modelagem estratégica explícita: subdomínios, contextos, linguagem ubíqua e context map.
2. Autonomia: database per service, nenhuma chamada HTTP entre serviços no fluxo de pedido, projeções
   locais do que vem de outros contextos.
3. Integração por eventos com as garantias que um sistema real precisa: outbox, inbox, retry, DLQ,
   filtros por tipo, tolerância a ordem e a duplicata.
4. Portabilidade: SNS + SQS (pull) e Pub/Sub (push) atrás da mesma porta; topologia declarada uma vez
   por serviço (`messaging.json`) e aplicada pelo Terraform de cada nuvem.
5. Independência de deploy: um repositório por serviço, cada um com seu Terraform, state e pipeline.
6. Microfrontends alinhados aos contextos, com deploy independente e um Event Inspector ao vivo.

Fora do escopo: autenticação de usuários (cliente "guest" com `customerId` gerado no navegador),
impostos, frete real, multi-região, alta disponibilidade.

## 2. Repositórios

| Repositório | Conteúdo |
| --- | --- |
| `lagoski-platform` | Terraform da base (rede, cluster/Cloud Run, Postgres, catálogo de tópicos, OIDC/WIF), compose do sistema inteiro, esta spec e os ADRs |
| `lagoski-contracts` | JSON Schemas e AsyncAPI dos eventos (Published Language) |
| `lagoski-catalog`, `-ordering`, `-inventory`, `-payment`, `-fulfillment`, `-notification` | um microsserviço cada: código, testes, Dockerfile, `infrastructure/` |
| `lagoski-bff` | Backend for Frontend: único HTTP público, SSE dos eventos, entrada do webhook do Stripe |
| `portfolio` (existente) | quatro microfrontends Lagoski + o host + a página de arquitetura |

## 3. Design estratégico

| Contexto | Tipo | Agregados | Vê "a camiseta" como |
| --- | --- | --- | --- |
| Catalog | Supporting | `Product`, `Variant` | produto com variantes (tamanho × cor) e preço de lista |
| Ordering | **Core** | `Cart`, `Order` | linha de pedido com preço congelado |
| Inventory | Supporting | `StockItem`, `Reservation` | SKU com em mãos e reservado |
| Payment | Generic | `Payment` | só um valor a cobrar |
| Fulfillment | Supporting | `Shipment` | itens de um pacote |
| Notification | Generic | — | dados para um e-mail |

Context map: Catalog e Ordering são upstream com **Open Host Service + Published Language**;
Inventory/Payment/Fulfillment são **Customer/Supplier** do Ordering; Payment usa **ACL** com o Stripe;
Notification é **Conformist**.

## 4. Saga do pedido (coreografia)

1. `POST /orders` → Ordering cria o pedido `PENDING` e grava `order.placed` no outbox.
2. Inventory reserva tudo ou nada (TTL 35 min) → `stock.reserved` ou `stock.reservation-rejected`.
3. Payment (com a projeção `PayableOrder`) abre um **Stripe Checkout Session** → `payment.requested`
   com `checkoutUrl`. O pedido vai para `AWAITING_PAYMENT`.
4. O cliente paga na página do Stripe e volta ao SPA. O **webhook** (`checkout.session.completed`)
   chega ao Payment → `payment.authorized`.
5. Ordering confirma → `order.confirmed`. Inventory dá baixa (`stock.committed`), Fulfillment cria a
   remessa, despacha e entrega (simulado), Notification "envia" e-mails.

Compensações: sem estoque → `order.cancelled (OUT_OF_STOCK)`; checkout expirado ou pagamento assíncrono
falho → `payment.declined` → `order.cancelled (PAYMENT_DECLINED)`; reserva vencida →
`reservation.expired` → cancelamento; `order.cancelled` libera a reserva e expira o checkout aberto;
pagamento que chega depois do cancelamento é estornado (`payment.refunded`).

Estados do pedido: `PENDING → AWAITING_PAYMENT → CONFIRMED → SHIPPED → DELIVERED`, ou `CANCELLED`.
Transições fora de ordem são ignoradas e registradas, nunca lançam (ADR 5).

## 5. Mensageria

- Envelope CloudEvents 1.0; atributos `ce_type`, `ce_source`, `ce_id`, `correlation_id`, `traceparent`.
- Tópicos da plataforma: `lagoski-<env>-<contexto>-events`.
- Por assinatura (do serviço consumidor): `lagoski-<env>-<serviço>-on-<contexto>`, com DLQ após 5
  entregas, filtro por `ce_type` e alarme de DLQ não vazia.
- `messaging.json` em cada serviço é a única fonte: o código assina a partir dele e o Terraform cria
  filas/assinaturas/filtros a partir dele.
- BFF assina todos os tópicos sem filtro (observer) e transmite por SSE.

| | AWS | GCP |
| --- | --- | --- |
| Tópico | SNS | Pub/Sub |
| Assinatura | SNS → SQS, `raw_message_delivery`, filter policy | push subscription com `filter` e token OIDC |
| Retry / DLQ | visibilidade com backoff no consumidor / redrive SQS | `retry_policy` exponencial / `dead_letter_policy` |
| Consumo | long polling (pull) | HTTP push no Cloud Run |

## 6. Serviços

TypeScript, Node 22, Fastify, Postgres (`pg`), Zod. Cada repositório tem um **chassis** igual
(`src/chassis`: HTTP, config, banco, migrações, outbox relay, inbox, CloudEvents, adapters de
mensageria, jobs, shutdown) e o código de domínio separado em `domain/`, `application/`,
`infrastructure/` e `contracts/`. Testes de domínio (Vitest) e teste de contrato contra o
`lagoski-contracts`.

## 7. Pagamento (Stripe sandbox)

Detalhado no [ADR 10](adr/0010-stripe-acl.md). Resumo: Checkout Sessions hospedado, chave restrita
`rk_test_`, idempotency keys, webhook verificado (via BFF na nuvem; `stripe listen` local),
métodos dinâmicos, sem `automatic_tax`. Segredos no Secrets Manager / Secret Manager, criados vazios
pelo Terraform e preenchidos fora dele (nunca no state).

## 8. Infraestrutura

`lagoski-platform` (aplicado primeiro): VPC, ECS cluster, Cloud Map `lagoski.local`, ALB, RDS Postgres 16,
tópicos SNS, OIDC do GitHub (AWS); VPC, acesso privado, Cloud SQL Postgres 16, tópicos Pub/Sub,
Artifact Registry, conta do BFF, Workload Identity Federation (GCP). Exporta `service_platform`, o
contrato lido pelos serviços via `terraform_remote_state`.

Cada serviço: `infrastructure/modules/{aws,gcp}-service` + `environments/{aws,gcp}/dev`, backend S3
(lockfile nativo) / GCS, state próprio, tags/labels padrão, CI com `fmt`, `validate` e `tflint`, deploy
manual por OIDC.

## 9. Frontend

No `portfolio`: `lagoski-catalog`, `lagoski-checkout`, `lagoski-orders`, `lagoski-inspector` (remotes)
compostos na rota `/projetos/lagoski` do host. Cliente HTTP + SSE para o BFF ou mock em memória que
simula o barramento (tópicos, filtros, filas, DLQ, duplicatas) com o mesmo contrato.

## 10. Verificação

| O quê | Como |
| --- | --- |
| Domínio e chassis | `pnpm test` em cada serviço |
| Contratos | `pnpm test:contracts` (CI na tag fixada do `lagoski-contracts`) |
| Terraform | `terraform fmt -check`, `validate` (aws/dev, gcp/dev), `tflint` |
| Sistema | `docker compose up` em `local/` + Stripe sandbox: caminho feliz até `DELIVERED`, sem estoque, idempotência do `POST /orders` |
| UI | Playwright no `portfolio` (modo mock) |
