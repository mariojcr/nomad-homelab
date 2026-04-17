variable "jellyfin-conf" {
  default = <<EOT

add_header X-XSS-Protection "1; mode=block" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer" always;
add_header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), display-capture=(), encrypted-media=(), fullscreen=(self), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(), screen-wake-lock=(), usb=(), xr-spatial-tracking=()" always;
add_header Content-Security-Policy "default-src 'none'; script-src 'self' 'unsafe-inline' https://www.gstatic.com/ https://www.youtube.com blob:; connect-src 'self'; img-src 'self' data: https: blob:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com/css2 blob:; font-src 'self' data: https://fonts.gstatic.com; manifest-src 'self'; media-src 'self' blob:; worker-src 'self' blob:; frame-ancestors 'self';" always;
add_header Cache-Control "private$jf_content";

location /metrics {
  return 403;
}

location / {
  proxy_pass http://$upstream;
  proxy_buffering off;
}

location /socket {
  proxy_pass http://$upstream;
}

location ~ /Items/(.*)/Images {
  add_header_inherit on;
  proxy_pass http://$upstream;
  proxy_cache jellyfin;
  proxy_cache_revalidate on;
  proxy_cache_lock on;
  add_header X-Cache-Status $upstream_cache_status;
}
EOT
}

variable "jellyfin-confd" {
  default = <<EOT
proxy_cache_path /var/cache/nginx_jellyfin levels=1:2 keys_zone=jellyfin:100m max_size=15g inactive=30d use_temp_path=off;
map $sent_http_content_type $jf_content {
  "default" "";
  "text/html" ", epoch";
  "text/javascript" ", max-age=2592000";
  "text/css" ", max-age=2592000";
  "application/vnd.ms-fontobject" ", max-age=31536000";
  "application/font-woff" ", max-age=31536000";
  "application/x-font-truetype" ", max-age=31536000";
  "application/x-font-opentype" ", max-age=31536000";
  "~font/" ", max-age=31536000";
  "~image/" ", max-age=31536000";
}
EOT
}
