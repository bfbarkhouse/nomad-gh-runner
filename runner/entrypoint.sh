#!/bin/bash
set -e
RUNNER_NAME="$(hostname)-$NOMAD_ALLOC_ID"
CONFIGURED=false

if [ ! -f ".runner" ]; then
  ./config.sh \
    --url "${GITHUB_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace \
    --ephemeral
fi
CONFIGURED=true

exec ./run.sh
