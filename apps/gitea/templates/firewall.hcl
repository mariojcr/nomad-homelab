variable "firewall_config" {
  description = "Config for Gitea firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ range nomadService "gitea-runner" }}{{ .Address }}:tcp:3000,{{ end }}{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:3000,{{ end }}{{ env "attr.unique.network.ip-address" }}:tcp:3000,{{ env "attr.unique.network.ip-address" }}:tcp:2222"
FW_ALLOW_OUT="0.0.0.0/0:tcp:443,0.0.0.0/0:tcp:80"
EOH
}
