require 'rails_helper'

RSpec.describe "Api::V1::Invitations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/invitations/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/invitations/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/invitations/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/invitations/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
