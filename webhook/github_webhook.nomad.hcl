job "webhook-github-runner" {
  datacenters = ["dc1"]
  type        = "service"
  node_pool   = "x86"

  group "webhook-handler" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    task "handler" {
      #driver = "podman"
      driver = "docker"
      config {
        image = "public.ecr.aws/a5j7d1g2/nomad-gh-webhook:latest"
        ports = ["http"]
      }

      env {
        GITHUB_ORG         = "bfbarkhouse"
        GITHUB_REPO        = "gha-demo"
        NOMAD_JOB_TEMPLATE = "github-runner"
        PORT               = "8080"
      }

      service {
        name = "webhook-github-runner"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.webhook.rule=PathPrefix(`/webhook`)",
          "traefik.http.middlewares.webhook.stripprefix.prefixes=/webhook",
          "traefik.http.routers.webhook.middlewares=webhook",
        ]
        address = "${attr.unique.platform.aws.public-ipv4}"
        #TODO: health check
      }

      resources {
        cpu    = 200
        memory = 128
      }

      vault {
        change_mode = "restart"
      }

      template {
        data = <<EOF
export GITHUB_WEBHOOK_SECRET="{{ with secret "kv/data/github" }}{{ .Data.data.webhook_secret }}{{ end }}"
export GITHUB_PAT="{{ with secret "kv/data/github" }}{{ .Data.data.pat }}{{ end }}"
export NOMAD_TOKEN="{{ with secret "kv/data/github" }}{{ .Data.data.nomad_token }}{{ end }}"
export NOMAD_ADDR="{{ with secret "kv/data/github" }}{{ .Data.data.nomad_addr }}{{ end }}"
EOF

        destination = "secrets/env"
        env         = true
      }
    }
  }
}
