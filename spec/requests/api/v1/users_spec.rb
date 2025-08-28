require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/signup" do
    let(:valid_params) { { username: 'newuser', email: 'test@example.com', password: 'password123', bio: 'Test bio' } }

    it "creates a new user with valid parameters" do
      expect {
        post "/api/v1/signup", params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['username']).to eq('newuser')
      expect(json_response['data']['email']).to eq('test@example.com')
      expect(json_response['data']['bio']).to eq('Test bio')
      expect(json_response['token']).to be_present
    end

    it "returns user serialized data" do
      post "/api/v1/signup", params: valid_params

      expect(json_response['data']).to include(
        'id',
        'username',
        'email',
        'bio',
        'created_at',
        'updated_at'
      )
    end

    it "generates authentication token for new user" do
      post "/api/v1/signup", params: valid_params

      token = json_response['token']
      decoded_token = JWT.decode(token, JwtRailsApiAuth.configuration.jwt_secret)[0]
      expect(decoded_token['user_id']).to eq(User.last.id)
    end

    it "requires username" do
      post "/api/v1/signup", params: valid_params.except(:username)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Username can't be blank")
    end

    it "requires unique username" do
      create(:user, username: 'existinguser')

      post "/api/v1/signup", params: valid_params.merge(username: 'existinguser')

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Username has already been taken")
    end

    it "requires email" do
      post "/api/v1/signup", params: valid_params.except(:email)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Email can't be blank")
    end

    it "requires unique email" do
      create(:user, email: 'existing@example.com')

      post "/api/v1/signup", params: valid_params.merge(email: 'existing@example.com')

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Email has already been taken")
    end

    it "requires valid email format" do
      post "/api/v1/signup", params: valid_params.merge(email: 'invalid-email')

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Email is invalid")
    end

    it "requires password" do
      post "/api/v1/signup", params: valid_params.except(:password)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Password can't be blank")
    end

    it "requires minimum password length" do
      post "/api/v1/signup", params: valid_params.merge(password: '123')

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors']).to include("Password is too short (minimum is 6 characters)")
    end

    it "allows optional bio" do
      expect {
        post "/api/v1/signup", params: valid_params.except(:bio)
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['bio']).to be_nil
    end

    it "handles multiple validation errors" do
      post "/api/v1/signup", params: { username: '', email: 'invalid', password: '12' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['errors'].length).to be >= 3
    end
  end

  describe "GET /api/v1/me" do
    let(:user) { create(:user) }
    let(:headers) { auth_headers_for(user) }

    it "returns current user information" do
      get "/api/v1/me", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['id']).to eq(user.id)
      expect(json_response['data']['username']).to eq(user.username)
      expect(json_response['data']['email']).to eq(user.email)
    end

    it "requires authentication" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['message']).to eq("Please log in")
    end

    it "handles invalid token" do
      invalid_headers = { "Authorization" => "Bearer invalid_token" }

      get "/api/v1/me", headers: invalid_headers

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['message']).to eq("Please log in")
    end
  end
end
