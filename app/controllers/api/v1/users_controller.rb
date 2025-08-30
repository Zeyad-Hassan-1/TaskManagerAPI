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

      # PUT /api/v1/profile
      def update_profile
        if current_user.update(profile_params)
          serialized_user = UserSerializer.new(current_user).serializable_hash
          render json: { data: serialized_user }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
        end
      end

      # PUT /api/v1/change_password
      def change_password
        if current_user.authenticate(params[:current_password])
          if params[:new_password] == params[:new_password_confirmation]
            if current_user.update(password: params[:new_password])
              render json: { message: "Password updated successfully" }, status: :ok
            else
              render json: { errors: current_user.errors.full_messages }, status: :unprocessable_content
            end
          else
            render json: { error: "New password confirmation doesn't match" }, status: :unprocessable_content
          end
        else
          render json: { error: "Current password is incorrect" }, status: :unprocessable_content
        end
      end

      # POST /api/v1/profile/picture
      def upload_profile_picture
        if params[:profile_picture].present?
          current_user.profile_picture.attach(params[:profile_picture])
          serialized_user = UserSerializer.new(current_user).serializable_hash
          render json: { data: serialized_user, message: "Profile picture updated successfully" }, status: :ok
        else
          render json: { error: "No file provided" }, status: :unprocessable_content
        end
      end

      private

      def user_params
        params.permit(:username, :password, :bio, :email)
      end

      def profile_params
        params.require(:user).permit(:username, :email, :bio)
      end

      def handle_invalid_record(e)
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end
    end
  end
end
