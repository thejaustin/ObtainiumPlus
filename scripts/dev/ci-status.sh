#!/usr/bin/env bash
# Show recent CI runs. With --log, tail the failed steps of the latest run.
set -euo pipefail
cd "$(dirname "$0")/../.."
if [[ "${1:-}" == "--log" ]]; then
    run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
    gh run view "$run_id" --log-failed | tail -100
else
    gh run list --limit 8
fi
