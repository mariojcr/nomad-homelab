job "gitea" {
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
      source = "gitea-data"
    }

    volume "database" {
      type   = "host"
      source = "gitea-database"
    }

    service {
      port         = 3000
      address_mode = "alloc"
      name         = "gitea-http"
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
        "nginx_domain=git.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=gitea",
        "private_access=true"
      ]
    }

    service {
      port         = 2222
      address_mode = "alloc"
      name         = "gitea-ssh"
      provider     = "nomad"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "gitea-svc-default"
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

    task "database" {
      driver = "podman"

      volume_mount {
        volume      = "database"
        destination = "/var/lib/postgresql/data"
      }

      config {
        image = "docker.io/postgres:17.9-alpine"
      }

      template {
        data        = <<EOH
POSTGRES_DB=gitea
POSTGRES_USER=gitea
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/gitea" }}{{ .db_password }}{{ end }}
EOH
        destination = "local/postgres.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
    }

    task "app" {
      driver = "podman"

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      config {
        image = "docker.io/gitea/gitea:1.25.5"
      }

      template {
        data        = var.gitea_env
        destination = "local/gitea.env"
        env         = true
        change_mode = "restart"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

  }
}
