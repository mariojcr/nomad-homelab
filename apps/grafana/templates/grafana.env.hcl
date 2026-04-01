variable "grafana-env" {
  default = <<EOT
GF_SECURITY_ADMIN_PASSWORD={{ with nomadVar "nomad/jobs/grafana" }}{{ .admin_password }}{{ end }}
GF_USERS_ALLOW_SIGN_UP=false
GF_PATHS_PROVISIONING=/local/provisioning
GF_INSTALL_PLUGINS=victoriametrics-logs-datasource
EOT
}
