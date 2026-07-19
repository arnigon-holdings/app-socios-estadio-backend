require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.hosts << "app"
  config.hosts << "host.docker.internal"
  config.hosts << /172\.(1[7-9]|2[0-9]|3[01])\.\d{1,3}\.\d{1,3}/
end
