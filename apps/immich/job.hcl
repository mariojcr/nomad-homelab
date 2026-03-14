job "immich" {
  type        = "service"
  datacenters = __DATACENTER__

  group "immich" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "data" {
      type   = "host"
      source = "immich-data"
    }

    volume "cache" {
      type   = "host"
      source = "immich-cache"
    }

    volume "database" {
      type   = "host"
      source = "immich-database"
    }

    service {
      port         = 2283
      address_mode = "alloc"
      name         = "immich-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/api/server/ping"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=immich.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=immich",
        "private_access=true"
      ]
    }

    service {
      port         = 8081
      address_mode = "alloc"
      name         = "immich-metrics"
      provider     = "nomad"
      tags = [
        "metrics=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "immich-services"
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

    task "server" {
      driver = "podman"

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      config {
        image   = "ghcr.io/immich-app/immich-server:v2.5.6"
        devices = ["/dev/dri/renderD128"]
      }

      template {
        data        = var.immich_environment
        destination = "local/immich.env"
        env         = true
      }

      resources {
        cpu    = 1000
        memory = 6144
      }
    }

    task "machine-learning" {
      driver = "podman"

      volume_mount {
        volume      = "cache"
        destination = "/cache"
      }

      config {
        image   = "ghcr.io/immich-app/immich-machine-learning:v2.5.6"
        devices = ["/dev/dri/renderD128"]
      }

      template {
        data        = var.immich_environment
        destination = "local/immich.env"
        env         = true
      }

      resources {
        cpu    = 1000
        memory = 3072
      }
    }

    task "redis" {
      driver = "podman"

      config {
        image = "docker.io/valkey/valkey:9.0.3-alpine"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      lifecycle {
        hook = "prestart"
        sidecar = true
      }
    }

    task "database" {
      driver = "podman"

      volume_mount {
        volume      = "database"
        destination = "/var/lib/postgresql/data"
      }

      config {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.3.0"
      }

      template {
        data        = <<EOH
POSTGRES_DB=immich
POSTGRES_USER=immich
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/immich" }}{{ .db_password }}{{ end }}
POSTGRES_INITDB_ARGS=--data-checksums
EOH
        destination = "local/postgres.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      lifecycle {
        hook = "prestart"
        sidecar = true
      }
    }

  }
}
