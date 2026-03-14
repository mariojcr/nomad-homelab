job "gitea-runner" {
  type        = "service"
  datacenters = __DATACENTER__

  group "svc" {
    # Aumenta count para más paralelismo de CI jobs
    count = 2

    update {
      max_parallel     = 1
      health_check     = "task_states"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      name         = "gitea-runner"
      port         = 8080
      address_mode = "alloc"
      provider     = "nomad"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "gitea-runner-${NOMAD_ALLOC_INDEX}"
        }
      }
    }

    task "network-rules" {
      driver = "podman"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      config {
        image   = "ghcr.io/mariojcr/net-nomad:1.0.0"
        cap_add = ["NET_ADMIN"]
      }
      template {
        data        = var.firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "runner" {
      driver = "podman"

      config {
        image   = "docker.io/gitea/act_runner:0.3.0"
      }

      env {
        # run.sh lee CONFIG_FILE para pasar --config al register y daemon
        CONFIG_FILE = "/local/config.yaml"
        # Nombre único por allocación para que Gitea los distinga
        GITEA_RUNNER_NAME = "nomad-${NOMAD_ALLOC_ID}"
      }

      template {
        data        = var.runner_env
        destination = "local/runner.env"
        env         = true
        change_mode = "restart"
      }

      template {
        data        = var.runner_config
        destination = "local/config.yaml"
        change_mode = "restart"
      }

      resources {
        cpu    = 2000
        memory = 1024
      }
    }
  }
}
