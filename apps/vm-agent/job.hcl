job "vm-agent" {
  datacenters = __DATACENTER__
  type        = "system"
  priority    = 100

  group "agent" {
    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vm-agent-monitoring"
        }
      }
    }

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      provider     = "nomad"
      address_mode = "alloc"
      port         = 8429
      name         = "vm-agent"
      tags = [
        "metrics=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/health"
        interval     = "10s"
        timeout      = "2s"
        port         = 8429
      }
    }

    task "network-rules" {
      driver = "podman"
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
      config {
        image      = "ghcr.io/mariojcr/net-nomad:1.0.0"
        cap_add    = ["NET_ADMIN"]
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

    task "collector" {
      driver = "podman"

      config {
        image      = "docker.io/victoriametrics/vmagent:v1.140.0"
        entrypoint = ["/local/entrypoint.sh"]
      }

      template {
        destination = "local/scrape.yaml"
        data        = var.scrape_config
      }

      template {
        destination = "local/entrypoint.sh"
        data        = var.entrypoint_config
        perms       = "755"
      }

      resources {
        cpu    = 100
        memory = 256
      }

    }
  }
}
