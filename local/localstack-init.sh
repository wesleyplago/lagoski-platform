#!/bin/bash
# GERADO por scripts/local-topology.mjs a partir do messaging.json de cada serviço.
# Mesma topologia que o Terraform cria na AWS: tópicos da plataforma, e para cada
# assinatura uma fila, uma DLQ (5 tentativas) e o filtro por ce_type.
set -euo pipefail

awslocal sns create-topic --name lagoski-dev-catalog-events >/dev/null
awslocal sns create-topic --name lagoski-dev-ordering-events >/dev/null
awslocal sns create-topic --name lagoski-dev-inventory-events >/dev/null
awslocal sns create-topic --name lagoski-dev-payment-events >/dev/null
awslocal sns create-topic --name lagoski-dev-fulfillment-events >/dev/null

# catalog

# ordering
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-catalog-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-catalog --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-catalog-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-catalog-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-catalog --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.catalog.product.published.v1\",\"lagoski.catalog.variant.price-changed.v1\",\"lagoski.catalog.product.discontinued.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-inventory-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-inventory --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-inventory-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-inventory-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-inventory --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.inventory.stock.reserved.v1\",\"lagoski.inventory.stock.reservation-rejected.v1\",\"lagoski.inventory.reservation.expired.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-payment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-payment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-payment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-payment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-payment --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.payment.payment.requested.v1\",\"lagoski.payment.payment.authorized.v1\",\"lagoski.payment.payment.declined.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-fulfillment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-ordering-on-fulfillment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-fulfillment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-fulfillment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-ordering-on-fulfillment --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.fulfillment.shipment.dispatched.v1\",\"lagoski.fulfillment.shipment.delivered.v1\"]}"}' >/dev/null

# inventory
awslocal sqs create-queue --queue-name lagoski-dev-inventory-on-catalog-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-inventory-on-catalog --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-inventory-on-catalog-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-catalog-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-inventory-on-catalog --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.catalog.product.published.v1\",\"lagoski.catalog.product.discontinued.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-inventory-on-ordering-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-inventory-on-ordering --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-inventory-on-ordering-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-ordering-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-inventory-on-ordering --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.ordering.order.placed.v1\",\"lagoski.ordering.order.confirmed.v1\",\"lagoski.ordering.order.cancelled.v1\"]}"}' >/dev/null

# payment
awslocal sqs create-queue --queue-name lagoski-dev-payment-on-ordering-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-payment-on-ordering --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-payment-on-ordering-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-ordering-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-payment-on-ordering --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.ordering.order.placed.v1\",\"lagoski.ordering.order.cancelled.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-payment-on-inventory-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-payment-on-inventory --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-payment-on-inventory-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-inventory-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-payment-on-inventory --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.inventory.stock.reserved.v1\"]}"}' >/dev/null

# fulfillment
awslocal sqs create-queue --queue-name lagoski-dev-fulfillment-on-ordering-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-fulfillment-on-ordering --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-fulfillment-on-ordering-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-ordering-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-fulfillment-on-ordering --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.ordering.order.confirmed.v1\"]}"}' >/dev/null

# notification
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-ordering-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-ordering --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-ordering-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-ordering-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-ordering --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.ordering.order.confirmed.v1\",\"lagoski.ordering.order.cancelled.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-payment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-payment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-payment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-payment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-payment --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.payment.payment.declined.v1\"]}"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-fulfillment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-notification-on-fulfillment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-fulfillment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-fulfillment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-notification-on-fulfillment --attributes '{"RawMessageDelivery":"true","FilterPolicyScope":"MessageAttributes","FilterPolicy":"{\"ce_type\":[\"lagoski.fulfillment.shipment.dispatched.v1\"]}"}' >/dev/null

# bff
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-catalog-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-catalog --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-catalog-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-catalog-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-catalog --attributes '{"RawMessageDelivery":"true"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-ordering-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-ordering --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-ordering-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-ordering-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-ordering --attributes '{"RawMessageDelivery":"true"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-inventory-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-inventory --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-inventory-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-inventory-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-inventory --attributes '{"RawMessageDelivery":"true"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-payment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-payment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-payment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-payment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-payment --attributes '{"RawMessageDelivery":"true"}' >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-fulfillment-dlq >/dev/null
awslocal sqs create-queue --queue-name lagoski-dev-bff-on-fulfillment --attributes '{"RedrivePolicy":"{\"deadLetterTargetArn\":\"arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-fulfillment-dlq\",\"maxReceiveCount\":\"5\"}"}' >/dev/null
awslocal sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:lagoski-dev-fulfillment-events --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:lagoski-dev-bff-on-fulfillment --attributes '{"RawMessageDelivery":"true"}' >/dev/null

touch /tmp/lagoski-ready
echo "topologia Lagoski pronta"
