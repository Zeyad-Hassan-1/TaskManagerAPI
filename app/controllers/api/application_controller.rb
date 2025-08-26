module Api
  class ApplicationController < ActionController::API
    include Authenticatable

    # Common API response methods
    def render_success(data, status = :ok)
      render json: { data: data }, status: status
    end

    private

  def render_error(message, status = :unprocessable_content)
    render json: { error: message }, status: status
  end

    def render_unauthorized(message = "Unauthorized")
      render json: { error: message }, status: :unauthorized
    end

    def render_forbidden(message = "Forbidden")
      render json: { message: message }, status: :forbidden
    end

    def render_not_found(message = "Resource not found")
      render json: { error: message }, status: :not_found
    end
  end
end
