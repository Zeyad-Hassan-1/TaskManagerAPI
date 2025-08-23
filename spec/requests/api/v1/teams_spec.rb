require 'rails_helper'

RSpec.describe 'Teams API', type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  before do
    # Create a team membership for the user
    create(:team_membership, user: user, team: team, role: :member)
  end

  describe 'GET /api/v1/teams' do
    it 'returns a list of teams' do
      get '/api/v1/teams'
      expect(response).to have_http_status(:unauthorized) # Should require authentication
    end
  end

  describe 'POST /api/v1/teams' do
    let(:valid_params) { { team: { name: 'New Team', discription: 'New team description' } } }

    it 'creates a new team' do
      expect {
        post '/api/v1/teams', params: valid_params
      }.to change(Team, :count).by(1)
      expect(response).to have_http_status(:unauthorized) # Should require authentication
    end
  end

  describe 'GET /api/v1/teams/:id' do
    it 'returns the team details' do
      get "/api/v1/teams/#{team.id}"
      expect(response).to have_http_status(:unauthorized) # Should require authentication
    end
  end
end
