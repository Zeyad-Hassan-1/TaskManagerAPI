module Api
  module V1
    class UsersController < Api::ApplicationController
      skip_before_action :authorized, only: [ :create ]
      rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid_record

      # POST /api/v1/users
      def create
        user = User.create!(user_params)
        @token = encode_token(user_id: user.id)
        serialized_user = UserSerializer.new(user).serializable_hash

        render json: {
          data: serialized_user,
          token: @token
        }, status: :created
      end

      # GET /api/v1/users/me
      def me
        serialized_user = UserSerializer.new(current_user).serializable_hash
        render json: { data: serialized_user }, status: :ok
      end

      private

      def user_params
        params.permit(:username, :password, :bio, :email)
      end

      def handle_invalid_record(e)
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end
    end
  end
end
