# frozen_string_literal: true

Aws.config.update(region: ENV['AWS_REGION']) if ENV['AWS_REGION'].present?

if defined?(Rails::Server) && ENV['AWS_ACCESS_KEY_ID'].blank? && ENV['AWS_PROFILE'].blank?
  Rails.logger.info('[AWS] credentials sourced from default chain (env / instance profile / shared profile)')
end
