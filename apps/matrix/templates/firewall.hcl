variable "firewall_config" {
  description = "Config for Matrix Synapse firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8008,{{ env "attr.unique.network.ip-address" }}:tcp:5432,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8008{{ end }},{{ range nomadService "mas-http" }}{{ .Address }}:tcp:8008{{ end }}"
FW_ALLOW_OUT="{{ range nomadService "mas-http" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}0.0.0.0/0:tcp:443,0.0.0.0/0:tcp:80"
EOH
}

variable "element_firewall_config" {
  description = "Config for Element Web firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8080,{{ env "attr.unique.network.ip-address" }}:tcp:8081,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8080,{{ .Address }}:tcp:8081{{ end }}"
EOH
}

variable "mas_firewall_config" {
  description = "Config for Matrix Authentication Service firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8080,{{ env "attr.unique.network.ip-address" }}:tcp:5432,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8080{{ end }},{{ range nomadService "matrix-http" }}{{ .Address }}:tcp:8080{{ end }}"
FW_ALLOW_OUT="{{ range nomadService "matrix-http" }}{{ .Address }}:tcp:{{ .Port }}{{ end }}"
EOH
}

variable "rtc_firewall_config" {
  description = "Config for LiveKit/JWT firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="0.0.0.0/0:udp,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:7880,{{ .Address }}:tcp:8080{{ end }}"
FW_ALLOW_OUT="{{ range nomadService "matrix-http" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:443,{{ end }}0.0.0.0/0:udp:19302"
EOH
}

variable "call_firewall_config" {
  description = "Config for Element Call firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8080,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8080{{ end }}"
EOH
}
