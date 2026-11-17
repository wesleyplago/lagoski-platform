# 9. Microfrontends por bounded context no portfólio

**Status:** aceito · 2026-11-17

## Decisão
O SPA vive no repositório `portfolio`, que já usa Module Federation (`@module-federation/vite`).
Cada contexto com UI vira um remote independente: catálogo, checkout, pedidos e Event Inspector.
O host compõe os quatro numa rota. Os remotes não se importam: conversam por eventos no navegador
(`CustomEvent`) com tipos num pacote de contratos, espelhando o backend.

## Consequências
Cada remote tem build e deploy próprios e falha isolada (`RemoteBoundary`). Sem BFF configurado ou
fora do ar, os remotes usam um mock em memória que simula o barramento com o mesmo contrato.
