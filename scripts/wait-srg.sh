#!/usr/bin/env bash
# Aguarda o resultado do SRG para o deployment atual, correlacionado pelo deployment.id.
# Sai com 0 se "pass" ou "warning", 1 se "fail"/"error" ou timeout.
# Uso: wait-srg.sh <deploy|rollback>
set -euo pipefail

KIND="$1"
source "$(dirname "$0")/lib.sh"
DEPLOYMENT_ID="${GITHUB_RUN_ID}-${KIND}"
TIMEOUT="${SRG_TIMEOUT_SECONDS:-600}"
DEADLINE=$((SECONDS + TIMEOUT))

# Evento gravado pelo workflow do Dynatrace depois da validação do SRG.
QUERY="fetch bizevents, from: now()-2h
| filter event.type == \"rollback.demo.validation\"
| filter deployment.id == \"${DEPLOYMENT_ID}\"
| sort timestamp desc
| limit 1
| fields validation.status"

run_query() {
  local token bearer
  bearer=$(dt_token)
  token=$(curl -fsS -X POST "${DT_ENV_URL}/platform/storage/query/v1/query:execute" \
    -H "Authorization: Bearer ${bearer}" -H "Content-Type: application/json" \
    -d "$(jq -n --arg q "$QUERY" '{query:$q}')" | jq -r '.requestToken // empty')
  [ -z "$token" ] && return 0
  for _ in $(seq 1 15); do
    local out state
    out=$(curl -fsS -G "${DT_ENV_URL}/platform/storage/query/v1/query:poll" \
      -H "Authorization: Bearer ${bearer}" --data-urlencode "request-token=${token}")
    state=$(echo "$out" | jq -r '.state')
    if [ "$state" = "SUCCEEDED" ]; then
      echo "$out" | jq -r '.result.records[0]["validation.status"] // empty'
      return 0
    fi
    sleep 2
  done
}

while [ $SECONDS -lt $DEADLINE ]; do
  STATUS=$(run_query || true)
  case "$STATUS" in
    pass|warning) echo "SRG (${DEPLOYMENT_ID}): ${STATUS} (saudável)"; exit 0 ;;
    fail|error) echo "SRG (${DEPLOYMENT_ID}): ${STATUS}"; exit 1 ;;
  esac
  echo "Aguardando resultado do SRG para ${DEPLOYMENT_ID}..."
  sleep 15
done

echo "SRG (${DEPLOYMENT_ID}): timeout sem resultado (tratado como falha)"
exit 1
