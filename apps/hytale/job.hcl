job "hytale" {
  type        = "service"
  datacenters = __DATACENTER__

  group "server" {
    update {
      healthy_deadline  = "30m"
      progress_deadline = "35m"
    }

    volume "data" {
      type   = "host"
      source = "hytale"
    }

    service {
      name         = "hytale"
      port         = 5520
      provider     = "nomad"
      address_mode = "alloc"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "hytale-gameservers"
          MAC                = "__MAC_HYTALE__"
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
        destination = "/hytale"
      }

      config {
        image              = "docker.io/eclipse-temurin:26-jre"
        image_pull_timeout = "30m"
        working_dir        = "/hytale/Servidor"
        entrypoint         = ["/bin/bash", "-c"]
        command            = "java -Xms4G -Xmx8G -XX:+UseG1GC -XX:+UseCompactObjectHeaders -XX:+UseStringDeduplication -XX:AOTCache=HytaleServer.aot -jar HytaleServer.jar --assets Assets.zip --disable-sentry"
        volumes = [
          "local/machine-id:/etc/machine-id:ro"
        ]
      }

      template {
        data        = "d6d52a7749b44745b763b84045949e23"
        destination = "local/machine-id"
      }

      resources {
        cpu    = 4000
        memory = 12288
      }
    }
  }
}
