# GitHub Runner on Nomad

This repository provides a setup for running ephemeral GitHub Actions self-hosted runners using HashiCorp Nomad.

## Structure

- `runner/`: Dockerfile, startup script and Nomad job for the runner
- `webhook/`: Dockerfile, webhook server application, and Nomad job for the webhook

## Setup Overview

### GitHub
- Create your GitHub repo for the code and Actions workflow you want to execute on the Nomad runner. Example: https://github.com/bfbarkhouse/gha-demo
    - Create a GitHub repo webhook:
        - Set the payload URL to the publically available endpoint of the webhook server running on Nomad. We are using Traefik, Consul and AWS ALB to expose the webhook to the internet.
        - Set the content type to "application/json"
        - Set event to individual event "workflow jobs"
        - Set a webhook secret
    - Create the workflow .yml file in .github/workflows
        - Set "runs-on: [self-hosted, nomad]
    - Create a GitHub personal access token (PAT) with read/write access to the repo

### HashiCorp Vault
- Ensure that your Nomad cluster is configured to authenticate with workload identity to your Vault cluster: https://developer.hashicorp.com/nomad/docs/integrations/vault/acl 
    - Create a new kv secrets engine v2 path (we are using /kv/data/github in this example) and input:
        - pat = your GitHub PAT
        - webhook_secret = your webhook secret
        - nomad_addr = your Nomad cluster address
        - nomad_token = A Nomad ACL token with permissions to submit jobs
    - Update the Vault ACL policy for the role your Nomad job is using to authenticate to Vault:
        - `path "kv/data/github" {
            capabilities = ["read"]
           }`
        - `path "kv/metadata/github" {
            capabilities = ["read"]
           }`

### Stage container images
- Build `/runner/Dockerfile` on a Linux x86_64 host
- Build `/webhook/Dockerfile` on a Linux x86_64 host
- Push these images to your registry of choice
- Update `/runner/github_runner.nomad.hcl` to point to the runner image with any required authentication options
- Update `/webhook/github_webhook.nomad.hcl` to point to the runner image with any required authentication options

### HashiCorp Nomad
- Submit job `/runner/github_runner.nomad.hcl`
- Submit job `/webhook/github_webhook.nomad.hcl`
- Verify the jobs are running and healthy

### GitHub Actions Workflow
- Push a commit to your GitHub repo
- Your Actions workflow should run and execute on the Nomad runner

