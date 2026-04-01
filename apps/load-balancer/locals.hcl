locals {
  files = [
    {
      data        = var.nginx-conf
      destination = "local/nginx.conf"
    },
    {
      data          = var.vhosts-confd
      destination   = "local/conf.d/vhosts.conf"
      change_mode   = "signal"
      change_signal = "SIGHUP"
    },
    {
      data        = var.minimal-conf
      destination = "local/conf/minimal.conf"
    },
    {
      data        = var.jellyfin-confd
      destination = "local/conf.d/jellyfin.conf"
    },
    {
      data        = var.jellyfin-conf
      destination = "local/conf/jellyfin.conf"
    },
    {
      data        = var.gitea-conf
      destination = "local/conf/gitea.conf"
    },
    {
      data        = var.vaultwarden-conf
      destination = "local/conf/vaultwarden.conf"
    },
    {
      data        = var.immich-conf
      destination = "local/conf/immich.conf"
    },
    {
      data        = var.grafana-conf
      destination = "local/conf/grafana.conf"
    },
    {
      data        = var.matrix-conf
      destination = "local/conf/matrix.conf"
    },
    {
      data        = var.matrix-web-conf
      destination = "local/conf/matrix-web.conf"
    },
    {
      data        = var.matrix-auth-conf
      destination = "local/conf/matrix-auth.conf"
    },
    {
      data        = var.matrix-admin-conf
      destination = "local/conf/matrix-admin.conf"
    },
    {
      data          = var.matrix-rtc-confd
      destination   = "local/conf.d/matrix-rtc.conf"
      change_mode   = "signal"
      change_signal = "SIGHUP"
    },
    {
      data        = var.matrix-rtc-conf
      destination = "local/conf/matrix-rtc.conf"
    },
    {
      data        = var.matrix-call-conf
      destination = "local/conf/matrix-call.conf"
    },
    {
      data        = var.materialious-conf
      destination = "local/conf/materialious.conf"
    },
    {
      data        = var.victorialogs-conf
      destination = "local/conf/victorialogs.conf"
    }
  ]
}
