# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  skip_before_action :authorized

  # Request reset (step 1)
# New version using username
  def create
    user = User.find_by(email: params[:email])
    if user
      user.generate_password_reset_token!
      # Send token via your preferred method (API response, SMS, etc.)
      render json: { 
        message: "Reset instructions sent",
        token: user.reset_token # In production, send this via email/SMS instead
      }
    else
      render json: { error: "Username not found" }, status: :not_found
    end
  end

  # Actual reset (step 2)
  def update
    user = User.find_by(reset_token: params[:token])
    if user&.reset_sent_at && !user.password_reset_expired?
      if user.update(password: params[:password], reset_token: nil)
        render json: { message: "Password updated" }
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid or expired token" }, status: :unprocessable_entity
    end
  end
end