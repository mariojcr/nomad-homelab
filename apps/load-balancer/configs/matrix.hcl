variable "matrix-conf" {
  default = <<EOT

client_max_body_size 100M;
proxy_read_timeout 86400s;
proxy_send_timeout 86400s;
proxy_buffering off;

add_header X-XSS-Protection "1; mode=block" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "interest-cohort=()" always;
add_header Content-Security-Policy "default-src 'none'; frame-ancestors 'none';" always;

location = /.well-known/matrix/client {
  add_header_inherit on;
  proxy_hide_header Access-Control-Allow-Origin;
  add_header Access-Control-Allow-Origin * always;
  add_header X-Robots-Tag "noindex, nofollow, noarchive, noimageindex" always;
  proxy_pass http://$upstream;
}

location /metrics {
  return 403;
}

# Bloquear admin API de Synapse desde acceso publico
location /_synapse/admin {
  allow {{ with nomadVar "nomad/jobs" }}{{ .home_cidr }}{{ end }};
  deny all;
  proxy_pass http://$upstream;
}

location / {
  proxy_pass http://$upstream;
}
EOT
}

variable "matrix-confd" {
  default = ""
}
