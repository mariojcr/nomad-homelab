variable "vhosts-confd" {
  default = <<EOT
{{- range nomadServices }}
{{- if .Tags | contains "nginx_enable=true" }}
{{- $domain := "" }}
{{- $certificate := "" }}
{{- $customConfig := "" }}
{{- range .Tags }}
  {{- $kv := (. | split "=") }}
  {{- if eq (index $kv 0) "nginx_domain" }}
      {{- $domain = (index $kv 1) }}
  {{- end }}
  {{- if eq (index $kv 0) "nginx_certificate" }}
      {{- $certificate = (index $kv 1) }}
  {{- end }}
  {{- if eq (index $kv 0) "nginx_custom_config" }}
      {{- $customConfig = (index $kv 1) }}
  {{- end }}
{{- end }}

upstream {{ .Name | toLower }} {
  {{- range nomadService .Name }}
  server {{ .Address }}:{{ .Port }} max_fails=3 fail_timeout=5s;
  {{- end }}
  keepalive 512;
}

server {
  listen 443 ssl;
  listen 443 quic;
  http2 on;
  add_header_inherit on;
  server_name {{ $domain }};

  ssl_certificate /etc/letsencrypt/live/{{ $certificate }}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/{{ $certificate }}/privkey.pem;

  set $upstream {{ .Name | toLower }};

  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_set_header X-Forwarded-Host $http_host;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection $connection_upgrade;

  {{- if .Tags | contains "private_access=true" }}
  allow {{ with nomadVar "nomad/jobs" }}{{ .home_cidr }}{{ end }};
  allow {{ with nomadVar "nomad/jobs" }}{{ .home_vpn_cidr }}{{ end }};
  deny all;
  {{- end }}

  {{- if $customConfig }}
  include conf/{{ $customConfig }}.conf;
  {{- else }}
  add_header X-XSS-Protection "1; mode=block" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "no-referrer" always;
  add_header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(self), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), usb=(), xr-spatial-tracking=()" always;
  add_header Content-Security-Policy "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self' https://fonts.googleapis.com/css; font-src 'self' https://fonts.gstatic.com; manifest-src 'self';" always;

  location /metrics {
    return 403;
  }

  location / {
    proxy_pass http://$upstream;
  }
  {{- end }}
}

{{- end }}
{{- end }}
EOT
}
