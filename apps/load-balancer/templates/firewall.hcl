variable "nginx_firewall_config" {
  description = "Config for nginx firewall rules"
  default     = <<EOH
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:80,0.0.0.0/0:tcp:443,0.0.0.0/0:udp:443"
FW_ALLOW_OUT="{{ range nomadServices }}{{ range nomadService .Name }}{{ if (.Tags | contains "nginx_enable=true") }}{{ .Address }}:tcp:{{ .Port }},{{ end }}{{ end }}{{ end }}{{ range nomadService "livekit-jwt" }}{{ .Address }}:tcp:{{ .Port }},{{ end }}"
EOH
}
