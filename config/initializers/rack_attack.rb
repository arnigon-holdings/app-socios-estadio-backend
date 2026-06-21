Rails.application.config.middleware.use Rack::Attack unless Rails.env.test?

class Rack::Attack
  throttle("req/ip", limit: 6, period: 60) do |req|
    req.ip if req.post? && req.path.start_with?("/api/v1/users")
  end

  throttle("login/ip", limit: 5, period: 60) do |req|
    req.ip if req.post? && req.path.start_with?("/api/admin/login")
  end

  throttle("api/all", limit: 100, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "Rate limit exceeded", retry_after: retry_after }.to_json]
    ]
  end unless Rails.env.test?
end
