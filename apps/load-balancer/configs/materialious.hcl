variable "materialious-conf" {
  default = <<EOT

underscores_in_headers on;

add_header X-XSS-Protection "1; mode=block" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer" always;
add_header Permissions-Policy "accelerometer=(), autoplay=(self), camera=(), display-capture=(), encrypted-media=(self), fullscreen=(self), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(), screen-wake-lock=(), usb=(), xr-spatial-tracking=()" always;

location /metrics {
  return 403;
}

location / {
  proxy_pass http://$upstream;
  proxy_buffering off;
}
EOT
}
