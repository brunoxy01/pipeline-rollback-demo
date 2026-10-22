#!/usr/bin/env bash
# Roda NA VM. Instala o Dynatrace Operator e o DynaKube.
# Requer: DT_API_TOKEN (operator + kubernetes monitoring) e DT_DATA_INGEST_TOKEN.
set -euo pipefail

DT_API_URL="${DT_API_URL:-https://bwm98081.live.dynatrace.com/api}"
CLUSTER_NAME="${CLUSTER_NAME:-rollback-demo-cluster}"

helm upgrade --install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator \
  --create-namespace -n dynatrace --atomic

kubectl -n dynatrace create secret generic "${CLUSTER_NAME}" \
  --from-literal=apiToken="${DT_API_TOKEN}" \
  --from-literal=dataIngestToken="${DT_DATA_INGEST_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: dynatrace.com/v1beta6
kind: DynaKube
metadata:
  name: ${CLUSTER_NAME}
  namespace: dynatrace
  annotations:
    feature.dynatrace.com/automatic-kubernetes-api-monitoring-cluster-name: "${CLUSTER_NAME}"
spec:
  apiUrl: ${DT_API_URL}
  metadataEnrichment:
    enabled: true
  oneAgent:
    cloudNativeFullStack: {}
  activeGate:
    capabilities:
      - kubernetes-monitoring
EOF

kubectl -n dynatrace get pods
