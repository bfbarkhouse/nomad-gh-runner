job "github-runner" {
  datacenters = ["dc1"]
  type        = "batch"
  node_pool   = "x86"


  parameterized {
    meta_required = [
      "github_url",
      "runner_token",
      "runner_labels"
    ]
  }

  group "runner" {
    count = 1

    task "runner" {
      driver = "docker"

      config {
        image = "public.ecr.aws/a5j7d1g2/nomad-gh-runner:latest"
      }

      env {
        GITHUB_URL    = "${NOMAD_META_github_url}"
        RUNNER_TOKEN  = "${NOMAD_META_runner_token}"
        RUNNER_LABELS = "${NOMAD_META_runner_labels}"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }

      kill_timeout = "30s"
    }
  }
}
