#!/usr/bin/env bash
# Trigger the Build APK workflow on main and watch it to completion.
# Pushing to main also triggers it automatically — use this only for re-runs.
set -euo pipefail
cd "$(dirname "$0")/../.."
gh workflow run build-apk.yml
sleep 10
run_id=$(gh run list --workflow=build-apk.yml --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch "$run_id" --exit-status
