module Api
  module V1
    class PasswordResetsController < Api::ApplicationController
      skip_before_action :authorized

      # Request reset (step 1)
      # POST /api/v1/password_resets
      def create
        user = User.find_by("LOWER(email) = LOWER(?)", params[:email])
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
      # PUT /api/v1/password_resets
      def update
        user = User.find_by(reset_token: params[:token])
        if user&.reset_sent_at && !user.password_reset_expired?
          # Validate password before attempting update
          if params[:password].blank?
            render json: { errors: [ "Password can't be blank" ] }, status: :unprocessable_content
          elsif params[:password].length < 6
            render json: { errors: [ "Password is too short (minimum is 6 characters)" ] }, status: :unprocessable_content
          elsif user.update(password: params[:password], reset_token: nil)
            render json: { message: "Password updated" }
          else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_content
          end
        else
          render json: { error: "Invalid or expired token" }, status: :unprocessable_content
        end
      end
    end
  end
end
