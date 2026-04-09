job "vl-server" {
  datacenters = __DATACENTER__
  type        = "service"

  group "server" {
    volume "data" {
      type   = "host"
      source = "victorialogs"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vl-server-monitoring"
        }
      }
    }

    service {
      provider     = "nomad"
      address_mode = "alloc"
      port         = 9428
      name         = "vl-server"
      tags = [
        "metrics=true",
        "nginx_enable=true",
        "nginx_domain=logs.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=victorialogs",
        "private_access=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/health"
        interval     = "10s"
        timeout      = "2s"
        port         = 9428
      }
    }

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
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

    task "server" {
      driver = "podman"

      config {
        image = "docker.io/victoriametrics/victoria-logs:v1.49.0"
        args = [
          "-storageDataPath=/storage",
          "-httpListenAddr=0.0.0.0:9428",
          "-retentionPeriod=4w",
          "-memory.allowedPercent=60",
          "-search.maxConcurrentRequests=4",
          "-search.maxQueryDuration=30s",
        ]
      }

      volume_mount {
        volume      = "data"
        destination = "/storage"
      }

      resources {
        cpu    = 200
        memory = 512
      }
    }
  }
}
