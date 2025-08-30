require 'rails_helper'

RSpec.describe "Api::V1::Activities", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/activities" do
    it "returns http success" do
      get "/api/v1/activities", headers: auth_headers_for(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /api/v1/activities/mark_all_read" do
    it "returns http success" do
      put "/api/v1/activities/mark_all_read", headers: auth_headers_for(user)
      expect(response).to have_http_status(:success)
    end
  end
end
