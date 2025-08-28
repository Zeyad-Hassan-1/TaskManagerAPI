# config/initializers/rack_attack.rb
# Rate limiting configuration for production security

return unless Rails.env.production? && ENV["RACK_ATTACK_ENABLED"] == "true"

class Rack::Attack
  # Configuration
  Rack::Attack.cache.store = Rails.cache

  # Throttling

  # Limit signup requests
  throttle("signup", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/signup" && req.post?
  end

  # Limit login requests
  throttle("login", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/login" && req.post?
  end

  # Limit password reset requests
  throttle("password_reset", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/password_resets" && req.post?
  end

  # General API rate limiting
  throttle("api", limit: 300, period: 1.hour) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Exponential backoff for repeated offenders
  blocklist("fail2ban pentesters") do |req|
    # Block if more than 20 requests in 10 minutes
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 20, findtime: 10.minutes, bantime: 1.hour) do
      # Track requests that hit the throttle
      CGI.unescape(req.query_string) =~ /^fail/ ||
      req.path.include?("/etc/passwd") ||
      req.path.include?("wp-admin") ||
      req.path.include?("wp-login")
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ {
        error: "Rate limit exceeded",
        message: "Too many requests. Please try again later.",
        retry_after: retry_after
      }.to_json ]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |request|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { error: "Forbidden", message: "Your request was blocked" }.to_json ]
    ]
  end
end

# Enable logging
ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
  req = payload[:request]
  Rails.logger.warn "[Rack::Attack][#{name}] #{req.env["REQUEST_METHOD"]} #{req.url} from #{req.ip}"
end
