job "vector" {
  datacenters = __DATACENTER__
  type        = "system"
  priority    = 80

  group "collector" {
    # Persist file checkpoints across alloc replacements so Vector
    # doesn't lose track of read positions when it restarts.
    ephemeral_disk {
      migrate = true
      sticky  = true
      size    = 150
    }

    volume "host-root" {
      source    = "host-root"
      type      = "host"
      read_only = true
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "vector-monitoring"
        }
      }
    }

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      name         = "vector"
      port         = 8686
      provider     = "nomad"
      address_mode = "alloc"
      tags = [
        "metrics=true"
      ]
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/health"
        interval     = "10s"
        timeout      = "2s"
        port         = 8686
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

    task "collector" {
      driver = "podman"

      config {
        image      = "docker.io/timberio/vector:0.54.0-alpine"
        entrypoint = ["/bin/sh", "-c"]
        args       = ["mkdir -p /alloc/data/vector-state && exec vector --config /local/vector.toml"]
      }

      artifact {
        source      = "https://download.db-ip.com/free/dbip-city-lite-2026-04.mmdb.gz"
        destination = "local/GeoLite2-City.mmdb"
        mode        = "file"
        options {
          archive = "gz"
        }
      }

      template {
        destination   = "local/vector.toml"
        data          = var.vector_config
        # Hot-reload instead of full restart when vl-server address changes.
        # This preserves the in-memory sink buffer and file checkpoints.
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay         = "5s"
      }

      volume_mount {
        volume      = "host-root"
        destination = "/host"
        read_only   = true
      }

      resources {
        cpu        = 100
        memory     = 384
        memory_max = 512
      }
    }
  }
}
