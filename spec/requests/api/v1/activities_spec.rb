require 'rails_helper'

RSpec.describe "Api::V1::Activities", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/v1/activities/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/activities/update"
      expect(response).to have_http_status(:success)
    end
  end

end
