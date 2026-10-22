#!/usr/bin/env bash
# Roda NA VM. Registra o runner self-hosted (label: rollback-demo).
# Requer RUNNER_TOKEN (GitHub: Settings > Actions > Runners > New self-hosted runner, ou
# `gh api -X POST repos/<dono>/<repo>/actions/runners/registration-token --jq .token`).
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/brunoxy01/pipeline-rollback-demo}"
VERSION="${RUNNER_VERSION:-$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | tr -d v)}"

mkdir -p ~/actions-runner && cd ~/actions-runner
curl -fsSL -o runner.tgz "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-x64-${VERSION}.tar.gz"
tar xzf runner.tgz

./config.sh --unattended --url "$REPO_URL" --token "$RUNNER_TOKEN" \
  --labels rollback-demo --name vm-rollback-demo --replace

sudo ./svc.sh install
sudo ./svc.sh start
