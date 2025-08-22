# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    include ActionController::Cookies
    before_action :authorized

    SECRET_KEY = JwtRailsApiAuth.configuration.jwt_secret

def encode_token(payload, exp = JwtRailsApiAuth.configuration.access_token_expiry.from_now)

  
  payload[:exp] = exp.to_i
  payload[:admin] = @user.admin? if @user.is_a?(User) && JwtRailsApiAuth.configuration.enable_roles
  
  token = JWT.encode(payload, SECRET_KEY)
  
end

    def decoded_token
      header = request.headers['Authorization']
      return nil unless header

      token = header.split(" ")[1]
      puts "🔍 DECODE_TOKEN DEBUG: Token: #{token}"
      
      begin
        decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: 'HS256', verify_expiration: true })
        puts "   Token valid, expires at: #{Time.at(decoded[0]['exp'])}" if decoded[0]['exp']
        decoded
      rescue JWT::ExpiredSignature => e
        puts "   ❌ Token expired: #{e.message}"
        @token_expired = true
        nil
      rescue JWT::DecodeError => e
        puts "   ❌ Token decode error: #{e.message}"
        nil
      end
    end

    def current_user
      return @current_user if defined?(@current_user)
      
      if decoded_token
        user_id = decoded_token[0]['user_id']
        @current_user = User.find_by(id: user_id)
      else
        @current_user = nil
      end
    end

    def current_admin
      current_user && (current_user.admin? || (decoded_token && decoded_token[0]['admin']))
    end

    def authorized
      # Check if token is expired first
      if @token_expired
        render json: { error: 'Token has expired' }, status: :unauthorized
        return false
      end
      
      unless current_user
        render json: { message: 'Please log in' }, status: :unauthorized
        return false
      end
      
      true
    end

    def admin_authorized
      authorized && current_admin
    end
  end
end