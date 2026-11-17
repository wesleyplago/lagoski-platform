#!/usr/bin/env node
// Gera local/localstack-init.sh a partir do messaging.json de cada serviço
// (checkouts irmãos: ../lagoski-<serviço>). Rode depois de mudar uma assinatura.
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const services = ['catalog', 'ordering', 'inventory', 'payment', 'fulfillment', 'notification', 'bff'];
const topics = ['catalog.events', 'ordering.events', 'inventory.events', 'payment.events', 'fulfillment.events'];
const prefix = 'lagoski-dev';
const topicName = (t) => `${prefix}-${t.replace(/\./g, '-')}`;
const arnTopic = (t) => `arn:aws:sns:us-east-1:000000000000:${topicName(t)}`;
const arnQueue = (q) => `arn:aws:sqs:us-east-1:000000000000:${q}`;

const lines = [
  '#!/bin/bash',
  '# GERADO por scripts/local-topology.mjs a partir do messaging.json de cada serviço.',
  '# Mesma topologia que o Terraform cria na AWS: tópicos da plataforma, e para cada',
  '# assinatura uma fila, uma DLQ (5 tentativas) e o filtro por ce_type.',
  'set -euo pipefail',
  '',
  ...topics.map((t) => `awslocal sns create-topic --name ${topicName(t)} >/dev/null`),
];

for (const svc of services) {
  const file = join(root, '..', `lagoski-${svc}`, 'messaging.json');
  if (!existsSync(file)) throw new Error(`não encontrei ${file}: clone os repositórios lado a lado`);
  const { subscriptions } = JSON.parse(readFileSync(file, 'utf8'));
  lines.push('', `# ${svc}`);
  for (const sub of subscriptions) {
    const q = `${prefix}-${svc}-on-${sub.topic.split('.')[0]}`;
    const redrive = JSON.stringify({ RedrivePolicy: JSON.stringify({ deadLetterTargetArn: arnQueue(`${q}-dlq`), maxReceiveCount: '5' }) });
    const attrs = { RawMessageDelivery: 'true' };
    if (sub.event_types.length) {
      attrs.FilterPolicyScope = 'MessageAttributes';
      attrs.FilterPolicy = JSON.stringify({ ce_type: sub.event_types });
    }
    lines.push(
      `awslocal sqs create-queue --queue-name ${q}-dlq >/dev/null`,
      `awslocal sqs create-queue --queue-name ${q} --attributes '${redrive}' >/dev/null`,
      `awslocal sns subscribe --topic-arn ${arnTopic(sub.topic)} --protocol sqs --notification-endpoint ${arnQueue(q)} --attributes '${JSON.stringify(attrs)}' >/dev/null`,
    );
  }
}
lines.push('', 'touch /tmp/lagoski-ready', 'echo "topologia Lagoski pronta"', '');
writeFileSync(join(root, 'local', 'localstack-init.sh'), lines.join('\n'), { mode: 0o755 });
console.log('local/localstack-init.sh atualizado');
