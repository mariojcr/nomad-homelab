job "matrix" {
  type        = "service"
  datacenters = __DATACENTER__

  group "synapse" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "data" {
      type   = "host"
      source = "matrix-synapse"
    }

    volume "database" {
      type   = "host"
      source = "matrix-postgres"
    }

    service {
      port         = 8008
      address_mode = "alloc"
      name         = "matrix-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        port         = 8008
        path         = "/health"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "matrix-synapse"
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

    task "postgres" {
      driver = "podman"

      volume_mount {
        volume      = "database"
        destination = "/var/lib/postgresql"
      }

      config {
        image = "docker.io/postgres:18.2-alpine"
      }

      template {
        data        = <<EOH
POSTGRES_DB=synapse
POSTGRES_USER=synapse
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/matrix" }}{{ .db_password }}{{ end }}
POSTGRES_INITDB_ARGS=--encoding=UTF8 --lc-collate=C --lc-ctype=C
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

    task "synapse" {
      driver = "podman"

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      config {
        image = "ghcr.io/element-hq/synapse:v1.150.0"
        volumes = [
          "local/homeserver.yaml:/data/homeserver.yaml:ro",
          "local/log.config:/data/log.config:ro",
        ]
      }

      env {
        SYNAPSE_CONFIG_PATH = "/data/homeserver.yaml"
      }

      template {
        data        = var.homeserver_config
        destination = "local/homeserver.yaml"
        change_mode = "restart"
      }

      template {
        data        = var.log_config
        destination = "local/log.config"
        change_mode = "restart"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }

  group "web" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      port         = 8080
      address_mode = "alloc"
      name         = "element-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        port         = 8080
        path         = "/"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix-web.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix-web"
      ]
    }

    service {
      port         = 8081
      address_mode = "alloc"
      name         = "element-admin-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        port         = 8081
        path         = "/"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix-admin.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix-admin",
        "private_access=true"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "matrix-web"
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
        data        = var.element_firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "element" {
      driver = "podman"

      config {
        image = "ghcr.io/element-hq/element-web:v1.12.13"
        volumes = [
          "local/config.json:/app/config.json:ro",
        ]
      }

      env {
        ELEMENT_WEB_PORT = "8080"
      }

      template {
        data        = var.element_config
        destination = "local/config.json"
        change_mode = "restart"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }

    task "element-admin" {
      driver = "podman"

      config {
        image = "oci.element.io/element-admin:0.1.11"
        volumes = [
          "local/admin-nginx.conf:/etc/nginx/conf.d/default.conf:ro",
        ]
      }

      env {
        SERVER_NAME = "matrix.__DOMAIN__"
      }

      template {
        data        = var.admin_nginx_config
        destination = "local/admin-nginx.conf"
        change_mode = "restart"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }

  group "auth" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    volume "mas-data" {
      type   = "host"
      source = "matrix-mas"
    }

    volume "mas-database" {
      type   = "host"
      source = "matrix-mas-postgres"
    }

    service {
      port         = 8080
      address_mode = "alloc"
      name         = "mas-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        port         = 8080
        path         = "/"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix-auth.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix-auth"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "matrix-mas"
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
        data        = var.mas_firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "mas-postgres" {
      driver = "podman"

      volume_mount {
        volume      = "mas-database"
        destination = "/var/lib/postgresql"
      }

      config {
        image = "docker.io/postgres:18.2-alpine"
      }

      template {
        data        = <<EOH
POSTGRES_DB=mas
POSTGRES_USER=mas
POSTGRES_PASSWORD={{ with nomadVar "nomad/jobs/matrix" }}{{ .db_password }}{{ end }}
POSTGRES_INITDB_ARGS=--encoding=UTF8 --lc-collate=C --lc-ctype=C
EOH
        destination = "local/postgres.env"
        env         = true
      }

      resources {
        cpu    = 300
        memory = 256
      }

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }
    }

    task "mas" {
      driver = "podman"

      volume_mount {
        volume      = "mas-data"
        destination = "/data"
      }

      config {
        image   = "ghcr.io/element-hq/matrix-authentication-service:1.14.0"
        volumes = [
          "local/config.yaml:/config/config.yaml:ro",
        ]
      }

      env {
        MAS_CONFIG = "/config/config.yaml"
      }

      template {
        data        = var.mas_config
        destination = "local/config.yaml"
        change_mode = "restart"
      }

      resources {
        cpu    = 300
        memory = 256
      }
    }
  }

  group "rtc" {

    update {
      health_check     = "task_states"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      port         = 7880
      address_mode = "alloc"
      name         = "livekit-http"
      provider     = "nomad"
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix-rtc.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix-rtc"
      ]
    }

    service {
      port         = 8080
      address_mode = "alloc"
      name         = "livekit-jwt"
      provider     = "nomad"
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "matrix-rtc"
          MAC                = "__MAC_MATRIX__"
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
        data        = var.rtc_firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "livekit" {
      driver = "podman"

      config {
        image = "docker.io/livekit/livekit-server:v1.10.1"
        args  = ["--config", "/local/livekit.yaml"]
      }

      template {
        data        = var.livekit_config
        destination = "local/livekit.yaml"
        change_mode = "restart"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }

    task "lk-jwt-service" {
      driver = "podman"

      config {
        image = "ghcr.io/element-hq/lk-jwt-service:0.4.2"
      }

      template {
        data        = <<EOH
LIVEKIT_URL=wss://matrix-rtc.__DOMAIN__/livekit/sfu
LIVEKIT_KEY=livekit-key
LIVEKIT_SECRET={{ with nomadVar "nomad/jobs/matrix" }}{{ .livekit_secret }}{{ end }}
LIVEKIT_JWT_BIND=0.0.0.0:8080
LIVEKIT_FULL_ACCESS_HOMESERVERS=matrix.__DOMAIN__
EOH
        destination = "local/jwt.env"
        env         = true
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }

  }

  group "call" {

    update {
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
    }

    service {
      port         = 8080
      address_mode = "alloc"
      name         = "element-call-http"
      provider     = "nomad"
      check {
        address_mode = "alloc"
        type         = "http"
        port         = 8080
        path         = "/"
        interval     = "30s"
        timeout      = "5s"
      }
      tags = [
        "nginx_enable=true",
        "nginx_domain=matrix-call.__DOMAIN__",
        "nginx_certificate=__DOMAIN__",
        "nginx_custom_config=matrix-call"
      ]
    }

    network {
      mode = "cni/containers"
      cni {
        args = {
          NOMAD_JOB_HOSTNAME = "matrix-call"
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
        data        = var.call_firewall_config
        destination = "local/firewall.env"
        env         = true
      }
      resources {
        cpu        = 10
        memory     = 10
        memory_max = 16
      }
    }

    task "element-call" {
      driver = "podman"

      config {
        image = "ghcr.io/element-hq/element-call:v0.18.0"
        volumes = [
          "local/config.json:/app/config.json:ro",
        ]
      }

      env {
        ELEMENT_CALL_PORT = "8080"
      }

      template {
        data        = var.element_call_config
        destination = "local/config.json"
        change_mode = "restart"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}

variable "admin_nginx_config" {
  description = "Nginx config for Element Admin (port 8081)"
  default     = <<EOT
server {
    listen 8081;
    root /dist;

    gzip on;
    gzip_static on;

    location /assets {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    location / {
        index /index.runtime.html /index.html;
        try_files $uri $uri/ /;
    }
}
EOT
}
