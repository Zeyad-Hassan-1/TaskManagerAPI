require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Api::V1::PasswordResets", type: :request do
  let(:user) { create(:user, email: 'user@example.com') }

  describe "POST /api/v1/password_resets" do
    it "generates reset token for existing user" do
      expect(user.reset_token).to be_nil

      post "/api/v1/password_resets", params: { email: user.email }

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Reset instructions sent")
      expect(json_response['token']).to be_present

      user.reload
      expect(user.reset_token).to be_present
      expect(user.reset_sent_at).to be_present
    end

    it "returns not found for non-existent email" do
      post "/api/v1/password_resets", params: { email: 'nonexistent@example.com' }

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Username not found")
    end

    it "updates existing reset token if user already has one" do
      user.generate_password_reset_token!
      old_token = user.reset_token
      old_sent_at = user.reset_sent_at

      sleep(1) # Ensure time difference
      post "/api/v1/password_resets", params: { email: user.email }

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.reset_token).not_to eq(old_token)
      expect(user.reset_sent_at).to be > old_sent_at
    end

    it "handles email parameter case insensitively" do
      post "/api/v1/password_resets", params: { email: user.email.upcase }

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Reset instructions sent")
    end
  end

  describe "PUT /api/v1/password_resets" do
    before do
      user.generate_password_reset_token!
    end

    let(:valid_params) { { token: user.reset_token, password: 'NewPassword123!' } }

    it "resets password with valid token" do
      put "/api/v1/password_resets", params: valid_params

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Password updated successfully")
    end

    it "authenticates user with new password" do
      put "/api/v1/password_resets", params: valid_params
      user.reload

      expect(user.authenticate('NewPassword123!')).to be_truthy
    end

    it "clears reset token after successful reset" do
      put "/api/v1/password_resets", params: valid_params
      user.reload

      expect(user.authenticate('NewPassword123!')).to be_truthy
      expect(user.reset_token).to be_nil
      expect(user.reset_sent_at).to be_nil
    end

    it "rejects invalid token" do
      put "/api/v1/password_resets", params: { token: 'invalid_token', password: 'NewPassword123!' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq("Invalid or expired token")
    end

    it "rejects expired token" do
      # Simulate expired token by setting reset_sent_at to past
      user.update!(reset_sent_at: 3.hours.ago)

      put "/api/v1/password_resets", params: valid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq("Invalid or expired token")
    end

    it "rejects password that's too short" do
      put "/api/v1/password_resets", params: { token: user.reset_token, password: '123' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Password is too short (minimum is 8 characters)")
    end

    it "rejects blank password" do
      put "/api/v1/password_resets", params: { token: user.reset_token, password: '' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Password can't be blank")
    end

    it "requires token parameter" do
      put "/api/v1/password_resets", params: { password: 'NewPassword123!' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq("Invalid or expired token")
    end

    it "requires password parameter" do
      put "/api/v1/password_resets", params: { token: user.reset_token }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Password can't be blank")
    end

    it "handles user without reset_sent_at" do
      user.update!(reset_sent_at: nil)

      put "/api/v1/password_resets", params: valid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq("Invalid or expired token")
    end

    context "when token is reused" do
      it "rejects already used token" do
        # First successful reset
        put "/api/v1/password_resets", params: valid_params
        expect(response).to have_http_status(:ok)

        # Try to reuse the same token
        user.generate_password_reset_token! # Generate new token but try to use old one
        old_token = valid_params[:token]

        put "/api/v1/password_resets", params: { token: old_token, password: 'AnotherPassword123!' }
        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Invalid or expired token")
      end
    end
  end
end
