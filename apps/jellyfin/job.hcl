job "jellyfin" {
  type        = "service"
  datacenters = __DATACENTER__

  group "jellyfin" {

    volume "data" {
      type   = "host"
      source = "jellyfin-data"
    }

    volume "cache" {
      type   = "host"
      source = "jellyfin-cache"
    }

    volume "anime" {
      type   = "host"
      source = "anime"
      read_only = true
    }

    volume "peliculas_a" {
      type   = "host"
      source = "peliculas_a"
      read_only = true
    }

    volume "peliculas_b" {
      type   = "host"
      source = "peliculas_b"
      read_only = true
    }

    volume "series" {
      type   = "host"
      source = "series"
      read_only = true
    }

    volume "musica" {
      type   = "host"
      source = "musica"
      read_only = true
    }

    volume "libros" {
      type   = "host"
      source = "libros"
      read_only = true
    }

    service {
      port         = 8096
      address_mode = "alloc"
      name         = "jellyfin-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        interval     = "30s"
        timeout      = "5s"
        path         = "/health"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=jellyfin.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=jellyfin",
        "metrics=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "jellyfin-services"
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
        destination = "/config"
      }

      volume_mount {
        volume      = "cache"
        destination = "/cache"
      }

      volume_mount {
        volume      = "anime"
        destination = "/media/anime"
        read_only   = true
      }

      volume_mount {
        volume      = "peliculas_a"
        destination = "/media/peliculas_a"
        read_only   = true
      }

      volume_mount {
        volume      = "peliculas_b"
        destination = "/media/peliculas_b"
        read_only   = true
      }

      volume_mount {
        volume      = "series"
        destination = "/media/series"
        read_only   = true
      }

      volume_mount {
        volume      = "musica"
        destination = "/media/musica"
        read_only   = true
      }

      volume_mount {
        volume      = "libros"
        destination = "/media/libros"
        read_only   = true
      }

      config {
        image   = "ghcr.io/jellyfin/jellyfin:10.11.8"
        devices = ["/dev/dri/renderD128"]
      }

      resources {
        cpu    = 16000
        memory = 16384
      }
    }

  }
}
