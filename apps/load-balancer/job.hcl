job "load-balancer" {
  datacenters = __DATACENTER__
  type        = "service"

  group "nginx" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "letsencrypt" {
      type      = "host"
      source    = "letsencrypt"
      read_only = true
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "load-balancer-system"
          MAC                = "__MAC_LB__"
        }
      }
    }

    service {
      name         = "load-balancer-http"
      port         = 80
      provider     = "nomad"
      address_mode = "alloc"
      check {
        address_mode = "alloc"
        type         = "http"
        path         = "/health-check"
        interval     = "10s"
        timeout      = "2s"
        port         = 80
      }
    }

    service {
      name         = "load-balancer-https"
      port         = 443
      provider     = "nomad"
      address_mode = "alloc"
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
        data        = var.nginx_firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "nginx" {
      driver = "podman"
      config {
        image      = "docker.io/nginx:1.29.5-alpine"
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf",
          "local/conf/:/etc/nginx/conf/",
          "local/conf.d/:/etc/nginx/conf.d/"
        ]
      }

      dynamic "template" {
        for_each = local.files
        content {
          data          = template.value.data
          destination   = template.value.destination
          change_mode   = try(template.value.change_mode, "restart")
          change_signal = try(template.value.change_signal, "")
        }
      }

      volume_mount {
        volume      = "letsencrypt"
        destination = "/etc/letsencrypt"
        read_only   = true
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
