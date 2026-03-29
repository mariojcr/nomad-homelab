job "qbittorrent" {
  datacenters = __DATACENTER__
  type        = "service"

  group "qbittorrent" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "downloads" {
      source = "qbittorrent-downloads"
      type   = "host"
    }

    volume "config" {
      source = "qbittorrent-config"
      type   = "host"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "qbittorrent-downloads"
          MAC                = "__MAC_QBIT__"
        }
      }
    }

    service {
      name         = "qbittorrent"
      port         = 8080
      provider     = "nomad"
      address_mode = "alloc"
      check {
        address_mode = "alloc"
        type         = "tcp"
        port         = 8080
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=qbittorrent.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=minimal",
        "private_access=true"
      ]
    }

    service {
      name         = "exporter"
      port         = 8090
      provider     = "nomad"
      address_mode = "alloc"
      tags = [
        "metrics=true"
      ]
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

    task "qbittorrent" {
      driver = "podman"

      artifact {
        source = "https://github.com/VueTorrent/VueTorrent/releases/latest/download/vuetorrent.zip"
        mode   = "dir"
      }

      artifact {
        source = "https://upd.emule-security.org/ipfilter.zip"
        mode   = "dir"
      }

      config {
        image      = "ghcr.io/qbittorrent/docker-qbittorrent-nox:5.1.4-2"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      volume_mount {
        volume      = "config"
        destination = "/config"
      }

      env {
        QBT_LEGAL_NOTICE = "confirm"
      }

      resources {
        cpu    = 500
        memory = 4096
      }
    }

    task "exporter" {
      driver = "podman"

      config {
        image      = "ghcr.io/martabal/qbittorrent-exporter:v1.13.4"
      }

      template {
        data        = var.exporter_env
        destination = "local/exporter.env"
        env         = true
      }

      lifecycle {
        hook    = "poststart"
        sidecar = true
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
