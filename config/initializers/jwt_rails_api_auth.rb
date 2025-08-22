JwtRailsApiAuth.configure do |config|
  config.jwt_secret = "test_secret_key"
  config.access_token_expiry = 10.minutes
  config.refresh_token_expiry = 7.days
  config.enable_roles = true
end
