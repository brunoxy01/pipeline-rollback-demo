#!/usr/bin/env bash
# Envia um evento SDLC de deployment ao Dynatrace.
# Uso: send-sdlc-event.sh <started|finished> <deploy|rollback> <success|failed|pending>
set -euo pipefail

STAGE="$1"; KIND="$2"; STATUS="$3"

source "$(dirname "$0")/lib.sh"

curl -fsS -X POST "${DT_INGEST_URL}/platform/ingest/v1/events.sdlc" \
  -H "Authorization: Bearer $(dt_token)" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "event.provider": "github-actions",
  "event.category": "deployment",
  "event.type": "${STAGE}",
  "event.status": "${STATUS}",
  "deployment.type": "${KIND}",
  "deployment.id": "${GITHUB_RUN_ID}-${KIND}",
  "task.id": "${GITHUB_RUN_ID}",
  "service": "demo-app",
  "product": "rollback-demo",
  "environment": "${ENVIRONMENT:-demo}",
  "release.version": "${APP_VERSION}",
  "vcs.ref": "${GITHUB_SHA}"
}
EOF
echo
