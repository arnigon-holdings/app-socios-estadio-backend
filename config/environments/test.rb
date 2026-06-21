Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.active_record.verbose_query_logs = true
end
