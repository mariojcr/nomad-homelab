resource "nomad_dynamic_host_volume" "grafana" {
  name      = "grafana"
  plugin_id = "custom-mkdir"
  node_id   = local.servers["thor"]
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
  parameters = {
    path = "/mnt/local/grafana"
  }
}

resource "nomad_job" "grafana" {
  jobspec = local.jobspec_for["apps/grafana"]

  depends_on = [
    nomad_dynamic_host_volume.grafana
  ]
}

resource "nomad_job" "node-exporter" {
  jobspec = local.jobspec_for["apps/node-exporter"]
}

resource "nomad_dynamic_host_volume" "victoriametrics" {
  name      = "victoriametrics"
  plugin_id = "custom-mkdir"
  node_id   = local.servers["thor"]
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
  parameters = {
    path = "/mnt/local/victoriametrics"
  }
}

resource "nomad_job" "vm-server" {
  jobspec = local.jobspec_for["apps/vm-server"]

  depends_on = [
    nomad_dynamic_host_volume.victoriametrics
  ]
}

resource "nomad_job" "vm-agent" {
  jobspec = local.jobspec_for["apps/vm-agent"]
}

resource "nomad_dynamic_host_volume" "victorialogs" {
  name      = "victorialogs"
  plugin_id = "custom-mkdir"
  node_id   = local.servers["thor"]
  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }
  parameters = {
    path = "/mnt/local/victorialogs"
  }
}

resource "nomad_job" "vl-server" {
  jobspec = local.jobspec_for["apps/vl-server"]

  depends_on = [
    nomad_dynamic_host_volume.victorialogs
  ]
}

resource "nomad_job" "vector" {
  jobspec = local.jobspec_for["apps/vector"]
}
