JwtRailsApiAuth.configure do |config|
  config.jwt_secret = "test_secret"
  config.access_token_expiry = 30.minutes
  config.refresh_token_expiry = 7.days
  config.enable_roles = true
end
