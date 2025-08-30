require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Api::V1::Auth", type: :request do
  let(:user) { create(:user, username: 'testuser', password: 'Password123!') }

  describe "POST /api/v1/login" do
    it "authenticates user with valid credentials" do
      post "/api/v1/login", params: { username: user.username, password: 'Password123!' }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['username']).to eq(user.username)
      expect(json_response['access_token']).to be_present
      expect(response.cookies['refresh_token']).to be_present
    end

    it "rejects invalid username" do
      post "/api/v1/login", params: { username: 'wronguser', password: 'Password123!' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['message']).to eq("User doesn't exist")
    end

    it "rejects invalid password" do
      post "/api/v1/login", params: { username: user.username, password: 'wrongpassword' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq("Invalid credentials")
    end

    it "creates a refresh token in the database" do
      expect {
        post "/api/v1/login", params: { username: user.username, password: 'Password123!' }
      }.to change(RefreshToken, :count).by(1)

      refresh_token = RefreshToken.last
      expect(refresh_token.user).to eq(user)
      expect(refresh_token.revoked_at).to be_nil
    end
  end

  describe "POST /api/v1/refresh" do
    let!(:refresh_token) { user.generate_refresh_token }

    it "generates new access token with valid refresh token via params" do
      raw_refresh_token = user.generate_refresh_token
      # In real apps, this would come from an HTTP-only cookie, but for testing we use params

      post "/api/v1/refresh", params: { refresh_token: raw_refresh_token }

      expect(response).to have_http_status(:ok)
      expect(json_response['access_token']).to be_present
      expect(response.cookies['refresh_token']).to be_present
    end

    it "generates new access token with valid refresh token via params" do
      post "/api/v1/refresh", params: { refresh_token: refresh_token }

      expect(response).to have_http_status(:ok)
      expect(json_response['access_token']).to be_present
      expect(response.cookies['refresh_token']).to be_present
    end

    it "revokes old refresh token after successful refresh" do
      digest = Digest::SHA256.hexdigest(refresh_token)
      old_token = RefreshToken.find_by(token_digest: digest)

      post "/api/v1/refresh", params: { refresh_token: refresh_token }

      expect(old_token.reload.revoked_at).to be_present
    end

    it "rejects missing refresh token" do
      post "/api/v1/refresh"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq("missing refresh token")
    end

    it "rejects invalid refresh token" do
      post "/api/v1/refresh", params: { refresh_token: "invalid_token" }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to include("Invalid or reused refresh token")
    end

    it "rejects expired refresh token" do
      # Create an expired refresh token
      expired_token_raw = SecureRandom.hex(16)
      expired_digest = Digest::SHA256.hexdigest(expired_token_raw)
      RefreshToken.create!(
        user: user,
        token_digest: expired_digest,
        expires_at: 1.day.ago
      )

      post "/api/v1/refresh", params: { refresh_token: expired_token_raw }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to include("Invalid or reused refresh token")
    end

    it "revokes all refresh tokens when reused token detected" do
      # Create a refresh token
      raw_token = user.generate_refresh_token

      # Use token once (should work and revoke the original token)
      post "/api/v1/refresh", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:ok)

      # Check that the original token is revoked in the database
      digest = Digest::SHA256.hexdigest(raw_token)
      original_token = RefreshToken.find_by(token_digest: digest)
      expect(original_token.revoked_at).to be_present

      # Reset the integration session to clear cookies completely
      reset!

      # Try to reuse the same token (should be unauthorized since it was revoked)
      post "/api/v1/refresh", params: { refresh_token: raw_token }
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to include("Invalid or reused refresh token")
    end
  end

  describe "POST /api/v1/logout" do
    let!(:refresh_token) { user.generate_refresh_token }

    it "logs out user with refresh token in params" do
      digest = Digest::SHA256.hexdigest(refresh_token)
      token_record = RefreshToken.find_by(token_digest: digest)

      expect {
        post "/api/v1/logout", params: { refresh_token: refresh_token }
      }.to change { RefreshToken.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Logged out")
      expect { token_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "logs out user with refresh token in params" do
      digest = Digest::SHA256.hexdigest(refresh_token)
      token_record = RefreshToken.find_by(token_digest: digest)

      expect {
        post "/api/v1/logout", params: { refresh_token: refresh_token }
      }.to change { RefreshToken.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Logged out")
      expect { token_record.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "handles logout without refresh token gracefully" do
      expect {
        post "/api/v1/logout"
      }.not_to change { RefreshToken.count }

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq("Logged out")
    end
  end
end
