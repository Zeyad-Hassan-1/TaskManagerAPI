require 'rails_helper'

RSpec.describe "Api::V1::Invitations", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/invitations" do
    it "returns http success" do
      get "/api/v1/invitations", headers: auth_headers_for(user)
      expect(response).to have_http_status(:success)
    end
  end
end
