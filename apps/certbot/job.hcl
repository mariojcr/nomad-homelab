job "certbot" {
  datacenters = __DATACENTER__
  type        = "batch"

  periodic {
    cron             = "0 0 * * 0"
    prohibit_overlap = true
  }

  group "certbot" {
    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "certbot-system"
        }
      }
    }

    volume "letsencrypt" {
      type   = "host"
      source = "letsencrypt"
    }

    task "renew" {
      driver = "podman"

      volume_mount {
        volume      = "letsencrypt"
        destination = "/etc/letsencrypt"
      }

      config {
        image = "docker.io/certbot/dns-ovh:v5.5.0"
        args  = ["renew"]
      }

      template {
        data        = var.credentials_ini
        destination = "local/credentials.ini"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
