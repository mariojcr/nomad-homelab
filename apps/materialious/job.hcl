job "materialious" {
  type        = "service"
  datacenters = __DATACENTER__

  group "materialious" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "materialious-data" {
      type   = "host"
      source = "materialious-data"
    }

    service {
      port         = 3000
      address_mode = "alloc"
      name         = "materialious-http"
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
        "nginx_domain=youtube.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=materialious",
        "private_access=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "materialious"
          MAC                = "__MAC_MATERIALIOUS__"
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

    task "materialious" {
      driver = "podman"

      volume_mount {
        volume      = "materialious-data"
        destination = "/materialious-data"
      }

      config {
        image = "docker.io/wardpearce/materialious-full:1.16.24"
      }

      template {
        data        = var.materialious_env
        destination = "local/materialious.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
