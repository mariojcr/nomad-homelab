variable "firewall_config" {
  description = "Config for VL Server firewall rules"
  default     = <<EOH
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:9428,{{ range nomadService "vector" }}{{ .Address }}:tcp:9428,{{ end }}{{ range nomadService "grafana" }}{{ .Address }}:tcp:9428,{{ end }}{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:9428{{ end }}"
EOH
}
