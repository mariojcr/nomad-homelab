variable "firewall_config" {
  description = "Config for Qbittorrent firewall rules"
  default     = <<EOH
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:8080,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:8080{{ end }},{{ range nomadService "vm-agent" }}{{ if eq .Node (env "node.unique.id") }}{{ .Address }}:tcp:8090{{ end }}{{ end }}"
FW_EGRESS="true"
NATPMP_ENABLED="true"
NATPMP_GATEWAY="{{ with nomadVar "nomad/jobs/qbittorrent" }}{{ .natpmp_gateway }}{{ end }}"
EOH
}
