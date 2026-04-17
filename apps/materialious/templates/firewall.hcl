variable "firewall_config" {
  description = "Config for Materialious firewall rules"
  default     = <<EOH
FW_DNS="{{ with nomadVar "nomad/jobs" }}{{ .dns_server_address }}{{ end }}"
FW_ALLOW_IN="{{ env "attr.unique.network.ip-address" }}:tcp:3000,{{ range nomadService "load-balancer" }}{{ .Address }}:tcp:3000{{ end }}"
FW_ALLOW_OUT="0.0.0.0/0:tcp:443,0.0.0.0/0:tcp:80"
EOH
}

variable "materialious_env" {
  description = "Materialious Full environment variables"
  default     = <<EOH
COOKIE_SECRET={{ with nomadVar "nomad/jobs/materialious" }}{{ .cookie_secret }}{{ end }}
DATABASE_CONNECTION_URI=sqlite:///materialious-data/materialious.db
ORIGIN=https://youtube.__DOMAIN__
PUBLIC_INTERNAL_AUTH=true
PUBLIC_REQUIRE_AUTH=true
PUBLIC_REGISTRATION_ALLOWED=false
PUBLIC_CAPTCHA_DISABLED=true
PUBLIC_PLAYER_ID=74edf1a3
PUBLIC_DANGEROUS_ALLOW_ANY_PROXY=true
PUBLIC_DEFAULT_RETURNYTDISLIKES_INSTANCE="https://returnyoutubedislikeapi.com"
PUBLIC_DEFAULT_SPONSERBLOCK_INSTANCE="https://sponsor.ajay.app"
PUBLIC_DEFAULT_DEARROW_INSTANCE="https://sponsor.ajay.app"
PUBLIC_DEFAULT_DEARROW_THUMBNAIL_INSTANCE="https://dearrow-thumb.ajay.app"
PUBLIC_DEFAULT_SETTINGS='{"darkMode":true,"region":"ES"}'
EOH
}
