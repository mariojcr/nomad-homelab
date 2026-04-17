variable "firewall_config" {
  description = "Config for SearXNG firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8080,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8080{{ end }}"
FW_ALLOW_OUT="0.0.0.0/0:tcp:443,0.0.0.0/0:tcp:80"
EOH
}
