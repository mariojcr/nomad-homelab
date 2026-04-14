job "vaultwarden" {
  type        = "service"
  datacenters = __DATACENTER__

  group "svc" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "data" {
      type   = "host"
      source = "vaultwarden"
    }

    service {
      port         = 80
      address_mode = "alloc"
      name         = "vaultwarden-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/alive"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=vault.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=vaultwarden",
        "private_access=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vaultwarden-svc-default"
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

    task "app" {
      driver = "podman"

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      config {
        image = "ghcr.io/dani-garcia/vaultwarden:1.35.7"
      }

      template {
        data        = var.vaultwarden_env
        destination = "local/vaultwarden.env"
        env         = true
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

  }
}
