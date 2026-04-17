variable "firewall_config" {
  description = "Config for Immich firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:2283,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:2283{{ end }},{{ range nomadService "vm-agent" }}{{ if eq .Node (env "node.unique.id") }}{{ .Address }}:tcp:8081{{ end }}{{ end }}"
FW_ALLOW_OUT="0.0.0.0/0:tcp:443,0.0.0.0/0:tcp:80"
EOH
}
