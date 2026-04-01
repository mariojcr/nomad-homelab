variable "firewall_config" {
  description = "Config for Grafana firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:3000,{{ range nomadService "load-balancer-http" }}{{ .Address }}:tcp:3000{{ end }},{{ range nomadService "vm-agent" }}{{ if eq .Node (env "node.unique.id") }}{{ .Address }}:tcp:3000{{ end }}{{ end }}"
FW_ALLOW_OUT="{{ range nomadService "vm-server" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}{{ range nomadService "vl-server" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}0.0.0.0/0:tcp:443"
EOH
}
