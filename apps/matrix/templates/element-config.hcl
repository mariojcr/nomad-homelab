variable "element_config" {
  description = "Element Web config.json"
  default     = <<EOT
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://matrix.__DOMAIN__",
      "server_name": "matrix.__DOMAIN__"
    }
  },
  "brand": "Element",
  "disable_guests": true,
  "disable_3pid_login": true,
  "default_theme": "dark",
  "room_directory": {
    "servers": ["matrix.__DOMAIN__"]
  },
  "show_labs_settings": true,
  "features": {
    "feature_video_rooms": true,
    "feature_element_call_video_rooms": true,
    "feature_pinning": true,
    "feature_notifications": true,
    "feature_ask_to_join": true,
    "feature_new_room_decoration_ui": true
  },
  "element_call": {
    "url": "https://matrix-call.__DOMAIN__",
    "use_exclusively": true,
    "brand": "Element Call"
  },
  "setting_defaults": {
    "urlPreviewsEnabled": true,
    "breadcrumbs": true,
    "UIFeature.registration": false,
    "UIFeature.passwordReset": false,
    "UIFeature.deactivate": false
  },
  "embedded_pages": {
    "login_for_welcome": true
  },
  "sso_redirect_options": {
    "immediate": true
  },
  "map_style_url": "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx"
}
EOT
}
