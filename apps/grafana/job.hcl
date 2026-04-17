job "grafana" {
  datacenters = __DATACENTER__
  type        = "service"

  group "grafana" {
    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "grafana-monitoring"
        }
      }
    }

    service {
      provider     = "nomad"
      address_mode = "alloc"
      port         = 3000
      name         = "grafana"
      tags = [
        "metrics=true",
        "nginx_enable=true",
        "nginx_domain=grafana.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=grafana",
        "private_access=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/api/health"
        interval     = "10s"
        timeout      = "2s"
        port         = 3000
      }
    }

    volume "data" {
      type   = "host"
      source = "grafana"
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

    task "grafana" {
      driver = "podman"
      user = "root"

      config {
        image = "docker.io/grafana/grafana:13.0.1"
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/grafana"
      }

      dynamic "template" {
        for_each = local.config_files
        content {
          data        = template.value.data
          destination = template.value.destination
          env         = try(template.value.env, false)
        }
      }

      dynamic "template" {
        for_each = local.dashboard_files
        content {
          data            = template.value.data
          destination     = template.value.destination
          left_delimiter  = "[["
          right_delimiter = "]]"
        }
      }

      resources {
        cpu    = 200
        memory = 512
      }

      restart {
        attempts = 3
        delay    = "10s"
      }
    }
  }
}
