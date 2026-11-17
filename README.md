# lagoski-platform

Base compartilhada do **Lagoski**, uma loja de camisetas que demonstra bounded contexts (DDD) em
microsserviços integrados só por eventos, na AWS (SNS + SQS) e no GCP (Pub/Sub), com o mesmo código.

Este repositório tem:

- o **Terraform da plataforma** (rede, compute, Postgres, catálogo de tópicos, OIDC para deploy);
- o **compose do sistema inteiro** para rodar local;
- a **[especificação](docs/SPEC.md)** e os **[ADRs](docs/adr)**.

Diagramas: [página de arquitetura no portfólio](https://github.com/wesleyplago/portfolio/blob/main/apps/portfolio/public/lagoski/arquitetura.html).

## Repositórios

| Repositório | Contexto | Papel |
| --- | --- | --- |
| [lagoski-catalog](https://github.com/wesleyplago/lagoski-catalog) | Catalog | produtos, variantes, preço |
| [lagoski-ordering](https://github.com/wesleyplago/lagoski-ordering) | Ordering (core) | carrinho, pedido, saga |
| [lagoski-inventory](https://github.com/wesleyplago/lagoski-inventory) | Inventory | reserva, baixa, expiração |
| [lagoski-payment](https://github.com/wesleyplago/lagoski-payment) | Payment | Stripe Checkout (sandbox) atrás de uma ACL |
| [lagoski-fulfillment](https://github.com/wesleyplago/lagoski-fulfillment) | Fulfillment | remessa simulada |
| [lagoski-notification](https://github.com/wesleyplago/lagoski-notification) | Notification | e-mails (simulados) |
| [lagoski-bff](https://github.com/wesleyplago/lagoski-bff) | Edge | API do SPA, SSE dos eventos, webhook do Stripe |
| [lagoski-contracts](https://github.com/wesleyplago/lagoski-contracts) | — | JSON Schemas e AsyncAPI |
| [portfolio](https://github.com/wesleyplago/portfolio) | — | microfrontends Lagoski |

## Rodar tudo local

Clone os repositórios lado a lado (`lagoski/lagoski-*`). Você precisa de Docker e de um
[sandbox do Stripe](https://docs.stripe.com/sandboxes) com uma **chave restrita** (`rk_test_…`) que
tenha escrita em Checkout Sessions e Refunds.

```bash
cp local/.env.example local/.env   # preencha STRIPE_API_KEY
```

```bash
stripe listen --forward-to localhost:8084/webhooks/stripe   # copie o whsec_ para local/.env
```

```bash
docker compose -f local/docker-compose.yml up --build -d
```

O BFF fica em http://localhost:8080 e o SPA (no `portfolio`) usa ele com
`VITE_LAGOSKI_API_URL=http://localhost:8080`. O Postgres fica na porta **5442** do host.

A topologia do LocalStack (`local/localstack-init.sh`) é gerada a partir do `messaging.json` de cada
serviço: `node scripts/local-topology.mjs`.

Verificado localmente com o Stripe sandbox: compra paga com o cartão de teste 4242 percorre
`order.placed → stock.reserved → payment.requested → payment.authorized → order.confirmed →
stock.committed → shipment.created → shipment.dispatched → shipment.delivered`, com dois e-mails;
pedido de SKU zerado termina em `order.cancelled (OUT_OF_STOCK)` sem tocar no Payment; repetir o
`POST /orders` devolve o mesmo pedido.

## Infraestrutura

```text
infrastructure/
├── bootstrap/{aws,gcp}/          bucket do state (aplicado uma vez, state local)
├── modules/
│   ├── aws-platform/             VPC, ECS, Cloud Map, ALB, RDS, tópicos SNS, OIDC do GitHub
│   └── gcp-platform/             VPC, Cloud SQL privado, tópicos Pub/Sub, Artifact Registry, WIF
└── environments/{aws,gcp}/dev/   backend S3 (lockfile) / GCS
```

Ordem: `bootstrap` → `platform` → serviços (qualquer ordem). A saída `service_platform` é o contrato
que cada serviço lê por `terraform_remote_state`; mudar o formato dela é mudar contrato.

```bash
cd infrastructure/bootstrap/aws && terraform init && terraform apply
cd ../../environments/aws/dev
cp backend.hcl.example backend.hcl && terraform init -backend-config=backend.hcl
terraform apply -var state_bucket=lagoski-tfstate-<account-id>
```

Depois, em cada repositório de serviço, configure as variáveis do GitHub (`AWS_DEPLOY_ROLE_ARN`,
`AWS_REGION`, `AWS_STATE_BUCKET`, e as do GCP) e grave os segredos do Stripe no Secrets Manager /
Secret Manager. O endpoint de webhook do Stripe aponta para `<bff>/api/webhooks/stripe`.

**Custo:** NAT, ALB e RDS cobram mesmo ociosos. Suba para demonstrar e destrua depois
(`terraform destroy` nos serviços, depois na plataforma).
