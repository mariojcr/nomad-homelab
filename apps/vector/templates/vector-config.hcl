variable "vector_config" {
  description = "Vector configuration for Nomad log collection"
  default     = <<EOH
data_dir = "/alloc/data/vector-state"

[api]
enabled = true
address  = "0.0.0.0:8686"

# ── Enrichment tables ─────────────────────────────────────────────────────────

[enrichment_tables.geoip_db]
type = "mmdb"
path = "/local/GeoLite2-City.mmdb"

# ── Sources ───────────────────────────────────────────────────────────────────
[sources.nomad_logs]
type      = "file"
include   = [
  "/host/var/lib/nomad/alloc/*/alloc/logs/*.stdout.0",
  "/host/var/lib/nomad/alloc/*/alloc/logs/*.stderr.0",
]
exclude = [
  "/host/var/lib/nomad/alloc/*/alloc/logs/*.fifo",
]
read_from = "end"
rotate_wait_secs = 30

# ── Transforms ────────────────────────────────────────────────────────────────
[transforms.parse_path]
type   = "remap"
inputs = ["nomad_logs"]
source = '''
  path_parts, err = parse_regex(.file, r'/host/var/lib/nomad/alloc/(?P<alloc_id>[^/]+)/alloc/logs/(?P<task>[^.]+)\.(?P<stream>stdout|stderr)\.')
  if err != null { abort }

  .alloc_id    = path_parts.alloc_id
  .task        = path_parts.task
  .stream      = path_parts.stream
  .host        = get_env_var("NOMAD_NODE_NAME") ?? get_hostname!()
  del(.source_type)

  # Capture the Nomad-prefix timestamp so historical logs keep their original
  # time instead of the Vector ingestion time. For JSON logs (e.g. nginx),
  # the merge below will overwrite .timestamp with the more precise value
  # embedded in the JSON (nginx time_iso8601 variable).
  line, line_err = parse_regex(.message, r'^(?P<ts>\S+)\s+\S+\s+[FP]\s+(?P<content>.*)$')
  if line_err == null {
    .message = line.content
    ts, ts_err = parse_timestamp(line.ts, "%+")
    if ts_err == null {
      .timestamp = ts
    }
  }

  # Promote JSON fields to top level for structured log emitters (e.g. nginx)
  parsed, parse_err = parse_json(.message)
  if parse_err == null && is_object(parsed) {
    ., _merge_err = merge(., parsed)
  }
'''

[transforms.normalize]
type   = "remap"
inputs = ["parse_path"]
source = '''
  # GeoIP lookup
  ip = string(."client.address") ?? ""
  if ip != "" {
    geo, geo_err = get_enrichment_table_record("geoip_db", {"ip": ip})
    if geo_err == null {
      ."geo.city.name"        = get(geo, ["city", "names", "en"]) ?? null
      ."geo.country.iso_code" = get(geo, ["country", "iso_code"]) ?? null
      ."geo.country.name"     = get(geo, ["country", "names", "en"]) ?? null
      ."geo.location.lat"     = to_float(get(geo, ["location", "latitude"]) ?? null) ?? null
      ."geo.location.lon"     = to_float(get(geo, ["location", "longitude"]) ?? null) ?? null
      ."geo.timezone"         = get(geo, ["location", "time_zone"]) ?? null
      ."geo.region.iso_code"  = get(geo, ["subdivisions", 0, "iso_code"]) ?? null
      ."geo.continent.code"   = get(geo, ["continent", "code"]) ?? null
      ."geo.postal_code"      = get(geo, ["postal", "code"]) ?? null
    }
  }

  # Remove empty fields emitted by nginx maps when not applicable
  # (e.g. tls.* on plain HTTP, error.type for 2xx/3xx responses)
  if ."tls.protocol.version" == ""     { del(."tls.protocol.version") }
  if ."tls.cipher_suite" == ""         { del(."tls.cipher_suite") }
  if ."network.protocol.version" == "" { del(."network.protocol.version") }
  if ."error.type" == ""               { del(."error.type") }

  # Convert upstream times to float; nginx emits "-" when no upstream
  uct = string(."upstream.connect_time") ?? "-"
  ."upstream.connect_time" = if uct == "-" || uct == "" { null } else { to_float(uct) ?? null }

  uht = string(."upstream.header_time") ?? "-"
  ."upstream.header_time" = if uht == "-" || uht == "" { null } else { to_float(uht) ?? null }

  urt = string(."upstream.response_time") ?? "-"
  ."upstream.response_time" = if urt == "-" || urt == "" { null } else { to_float(urt) ?? null }

  # Parse user agent
  ua = string(."user_agent.original") ?? ""
  if ua != "" {
    parsed_ua = parse_user_agent(ua)
    ."user_agent.name"        = string(parsed_ua.browser.family) ?? null
    ."user_agent.os.name"     = string(parsed_ua.os.family) ?? null
    ."user_agent.device.type" = string(parsed_ua.device.category) ?? null
  }
'''

# ── Sinks ─────────────────────────────────────────────────────────────────────
{{ $vl := nomadService "vl-server" }}
{{ if gt (len $vl) 0 }}{{ with index $vl 0 }}
[sinks.victoria_logs]
type   = "http"
inputs = ["normalize"]
uri    = "http://{{ .Address }}:{{ .Port }}/insert/jsonline?_stream_fields=alloc_id,task,stream,host,server.address,geo.country.iso_code&_msg_field=message&_time_field=timestamp"
method = "post"
{{ end }}{{ else }}
[sinks.victoria_logs]
type   = "http"
inputs = ["normalize"]
uri    = "http://127.0.0.1:9428/insert/jsonline?_stream_fields=alloc_id,task,stream,host,server.address,geo.country.iso_code&_msg_field=message&_time_field=timestamp"
method = "post"
{{ end }}

[sinks.victoria_logs.encoding]
codec = "json"

[sinks.victoria_logs.framing]
method = "newline_delimited"

[sinks.victoria_logs.batch]
max_bytes    = 1048576
timeout_secs = 5

[sinks.victoria_logs.buffer]
type       = "memory"
max_events = 50000
when_full  = "drop_newest"
EOH
}
