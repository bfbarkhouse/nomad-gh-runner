#!/bin/bash
set -euo pipefail

cd /runner

RUNNER_NAME="$(hostname)"
RUNNER_WORKDIR="_work"
#RUNNER_LABELS="${RUNNER_LABELS:-nomad}"
CONFIGURED=false

function cleanup {
  echo "[CLEANUP] Deregistering GitHub runner..."
  if [[ "$CONFIGURED" = true ]]; then
    echo "[CLEANUP] Fetching runner ID..."
    RUNNER_ID=$(curl -s -H "Authorization: token $RUNNER_TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "$GITHUB_URL/actions/runners" | \
      jq ".runners[] | select(.name==\"$RUNNER_NAME\") | .id")

    if [[ -n "$RUNNER_ID" ]]; then
      echo "[CLEANUP] Deleting runner ID: $RUNNER_ID"
      curl -s -X DELETE -H "Authorization: token $RUNNER_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "$GITHUB_URL/actions/runners/$RUNNER_ID"
    else
      echo "[CLEANUP] Runner ID not found."
    fi

    ./config.sh remove --unattended --token "$RUNNER_TOKEN"
  fi
}
trap cleanup EXIT

echo "[SETUP] Registering GitHub runner..."
./config.sh \
  --url "$GITHUB_URL" \
  --token "$RUNNER_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace
CONFIGURED=true

echo "[RUNNER] Starting GitHub runner..."
exec ./run.sh --once
