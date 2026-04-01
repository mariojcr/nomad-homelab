variable "firewall_config" {
  description = "Config for Vector firewall rules"
  default     = <<EOH
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8686"
FW_ALLOW_OUT="{{ range nomadService "vl-server" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}"
EOH
}
