job "vm-server" {
  datacenters = __DATACENTER__
  type        = "service"

  group "server" {
    volume "data" {
      type   = "host"
      source = "victoriametrics"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vm-server-monitoring"
        }
      }
    }

    service {
      provider     = "nomad"
      address_mode = "alloc"
      port         = 8428
      name         = "vm-server"
      tags = [
        "metrics=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/health"
        interval     = "10s"
        timeout      = "2s"
        port         = 8428
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

    task "server" {
      driver = "podman"

      config {
        image = "docker.io/victoriametrics/victoria-metrics:v1.138.0"
        args = [
          "-storageDataPath=/storage",
          "-httpListenAddr=0.0.0.0:8428",
          "-retentionPeriod=1y",
          "-memory.allowedPercent=60",
          "-search.maxConcurrentRequests=4",
          "-search.maxQueryDuration=30s",
          "-search.maxQueueDuration=10s",
          "-dedup.minScrapeInterval=10s",
          "-logNewSeries=false",
          "-cacheExpireDuration=30m"
        ]
      }

      volume_mount {
        volume      = "data"
        destination = "/storage"
      }

      resources {
        cpu    = 300
        memory = 2048
      }

    }
  }
}
