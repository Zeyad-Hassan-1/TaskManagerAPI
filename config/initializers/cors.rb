# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow CORS from configured origins
    origins do |origin|
      # In development, allow localhost
      if Rails.env.development?
        origin =~ /\Ahttps?:\/\/localhost(:\d+)?\z/
      else
        # In production, use environment variable or allow all
        cors_origins = ENV.fetch("CORS_ORIGINS", "*").split(",")
        cors_origins.include?("*") || cors_origins.include?(origin)
      end
    end

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
