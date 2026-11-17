# 3. CloudEvents como envelope e versão no tipo

**Status:** aceito · 2026-11-17

## Decisão
Envelope CloudEvents 1.0 em modo estruturado. O tipo carrega a versão maior:
`lagoski.<contexto>.<agregado>.<fato>.v<N>`. Schemas em JSON Schema 2020-12 no `lagoski-contracts`.

## Regras de evolução
Campo opcional novo mantém a versão. Quebra (campo obrigatório novo, remoção, mudança de significado)
gera `v2` publicado em paralelo ao `v1` até todos os consumidores migrarem. Consumidores são
tolerant readers. O CI do repositório de contratos bloqueia quebra sem versão nova; o CI de cada
serviço valida os eventos que ele produz contra os schemas numa tag fixada.
