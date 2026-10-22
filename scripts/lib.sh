#!/usr/bin/env bash
# Funções comuns: obtém token OAuth (expira em 5 min, por isso é pedido a cada chamada).
# Requer DT_ENV_URL, DT_CLIENT_ID, DT_CLIENT_SECRET, DT_ACCOUNT_URN.
dt_token() {
  curl -fsS -X POST https://sso.dynatrace.com/sso/oauth2/token \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${DT_CLIENT_ID}" \
    --data-urlencode "client_secret=${DT_CLIENT_SECRET}" \
    --data-urlencode "resource=${DT_ACCOUNT_URN}" \
    --data-urlencode "scope=storage:events:read storage:bizevents:read storage:buckets:read openpipeline:events.sdlc:ingest" \
    | jq -r .access_token
}

# Ingestão usa o domínio "live"; consultas usam "apps".
DT_INGEST_URL="${DT_ENV_URL/.apps./.live.}"
