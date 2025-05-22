# GitHub Runner on Nomad

This repository provides a setup for running ephemeral GitHub Actions self-hosted runners using HashiCorp Nomad.

## Structure

- `runner/`: Dockerfile, startup script and Nomad job for the runner
- `webhook/`: Dockerfile, webhook server application, and Nomad job for the webhook

## Setup Overview
Prereqs:
- Create your GitHub repo for the code and Actions workflow you want to execute on the Nomad runner. Example: https://github.com/bfbarkhouse/gha-demo
- Create a GitHub repo webhook:
    - Set the payload URL to the publically available webhook URL
    - Set the content type to "application/json"
    - Set event to individual event "workflow jobs"
    - Set a webhook secret
- Create the workflow .yml file in .github/workflows
    - Set "runs-on: [self-hosted, nomad]
- Create a GitHub personal access token (PAT)
- Ensure that your Nomad cluster is integrated with your Vault cluster
    - Create a new kv secrets engine path (we are using /kv/data/github in this example) and input:
        - pat = your GitHub PAT
        - webhook_secret = your webhook secret
        - nomad_addr = your Nomad cluster address
        - nomad_token = A Nomad ACL token with permissions to submit jobs
    - Update the Vault ACL policy for the role your Nomad job is using to authenticate to Vault:
        - path "kv/data/github" {capabilities = ["read"]}
        - path "kv/metadata/github" {capabilities = ["read"]}

1. Build and push the Docker images
2. Submit the Nomad jobs and ensure they are healthy
3. Push a commit to your GitHub repo
4. Your Actions workflow should run and execute on the Nomad runner

