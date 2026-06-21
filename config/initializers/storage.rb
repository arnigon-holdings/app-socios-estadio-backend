# Store files locally in development, use R2 in production
if ENV["ACTIVE_STORAGE_SERVICE"] == "r2"
  require "active_storage/service/r2_service"

  Rails.application.config.active_storage.service = :r2
else
  Rails.application.config.active_storage.service = :local
end
