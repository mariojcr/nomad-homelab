variable "nginx-conf" {
  default = <<EOT
user nginx;
worker_processes auto;
pid /run/nginx.pid;
pcre_jit on;

events {
  worker_connections 4096;
  use epoll;
  multi_accept on;
}

http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  types_hash_max_size 2048;

  client_body_timeout 10s;
  client_header_timeout 10s;
  keepalive_timeout 30;
  send_timeout 10s;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # OTel normalization maps — pre-process fields nginx can derive cheaply
  # so Vector doesn't have to touch these for every log line.
  map $server_protocol $otel_protocol_version {
    "HTTP/1.0"  "1.0";
    "HTTP/1.1"  "1.1";
    "HTTP/2.0"  "2";
    "HTTP/3.0"  "3";
    default     "";
  }

  map $ssl_protocol $otel_tls_version {
    "TLSv1.2"   "1.2";
    "TLSv1.3"   "1.3";
    default     "";
  }

  # IPv6 addresses contain ':', IPv4 don't
  map $remote_addr $otel_network_type {
    ~:        "ipv6";
    default   "ipv4";
  }

  # error.type: status code string for 4xx/5xx, empty otherwise
  map $status $otel_error_type {
    ~^[45]    $status;
    default   "";
  }

  # Clean url.query: use $args (without leading ?)
  map $args $otel_url_query {
    ""      "";
    default $args;
  }

  # Clean optional string fields: emit empty instead of "-"
  map $http_referer $otel_referer {
    ""      "";
    default $http_referer;
  }

  map $upstream_addr $otel_upstream_addr {
    "-"     "";
    ""      "";
    default $upstream_addr;
  }

  # WebSocket: set Connection header only when Upgrade is present
  map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      '';
  }

  # Upstream times as numbers: emit 0 when no upstream (nginx writes "-")
  map $upstream_connect_time $otel_upstream_connect_time {
    ~^[0-9.]+$  $upstream_connect_time;
    default     0;
  }

  map $upstream_header_time $otel_upstream_header_time {
    ~^[0-9.]+$  $upstream_header_time;
    default     0;
  }

  map $upstream_response_time $otel_upstream_response_time {
    ~^[0-9.]+$  $upstream_response_time;
    default     0;
  }

  log_format main escape=json
    '{'
      '"timestamp":"$time_iso8601",'
      '"http.request.method":"$request_method",'
      '"url.scheme":"$scheme",'
      '"url.full":"$scheme://$host$request_uri",'
      '"url.path":"$uri",'
      '"url.query":"$otel_url_query",'
      '"http.response.status_code":$status,'
      '"http.response.body.size":$body_bytes_sent,'
      '"http.request.size":$request_length,'
      '"http.request.header.referer":"$otel_referer",'
      '"user_agent.original":"$http_user_agent",'
      '"client.address":"$remote_addr",'
      '"client.port":$remote_port,'
      '"server.address":"$host",'
      '"server.port":$server_port,'
      '"network.type":"$otel_network_type",'
      '"network.protocol.name":"http",'
      '"network.protocol.version":"$otel_protocol_version",'
      '"tls.protocol.version":"$otel_tls_version",'
      '"tls.cipher_suite":"$ssl_cipher",'
      '"http.request.id":"$request_id",'
      '"duration":$request_time,'
      '"upstream.address":"$otel_upstream_addr",'
      '"upstream.status":"$upstream_status",'
      '"upstream.connect_time":$otel_upstream_connect_time,'
      '"upstream.header_time":$otel_upstream_header_time,'
      '"upstream.response_time":$otel_upstream_response_time,'
      '"error.type":"$otel_error_type"'
    '}';

  access_log /dev/stdout main;
  error_log /dev/stderr;

  ssl_session_cache shared:SSL:15m;
  ssl_session_timeout 1d;
  ssl_session_tickets off;
  ssl_buffer_size 1400;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
  ssl_ecdh_curve X25519:prime256v1:secp384r1;
  ssl_prefer_server_ciphers off;
  ssl_dhparam /etc/letsencrypt/dhparam.pem;

  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
  add_header Alt-Svc 'h3=":443"; ma=86400' always;

  server {
    listen 80 default_server;

    location = /health-check {
      access_log off;
      allow 127.0.0.1/32;
      allow 192.168.0.0/16;
      allow 172.16.0.0/12;
      allow 10.0.0.0/8;
      deny all;
      return 200;
    }

    location / {
      return 444;
    }
  }

  server {
    listen 443 ssl default_server;
    listen 443 quic default_server;
    http2 on;
    ssl_reject_handshake on;
  }

  include /etc/nginx/conf.d/*.conf;

}
EOT
}
