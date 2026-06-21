ENV["RAILS_ENV"] ||= "test"
require_relative "../config/application"
Rails.application.initialize!
require "rails/test_help"

class ActiveSupport::TestCase
  fixtures :all
end
