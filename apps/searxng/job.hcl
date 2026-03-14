job "searxng" {
  type        = "service"
  datacenters = __DATACENTER__

  group "searxng" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "data" {
      type   = "host"
      source = "searxng-data"
    }

    service {
      port         = 8080
      address_mode = "alloc"
      name         = "searxng-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=search.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=minimal",
        "private_access=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "searxng-services"
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

    task "searxng" {
      driver = "podman"

      volume_mount {
        volume      = "data"
        destination = "/etc/searxng"
      }

      config {
        image = "docker.io/searxng/searxng:2026.2.11-970f2b843"
      }

      env {
        SEARXNG_BASE_URL = "https://search.__DOMAIN__/"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
