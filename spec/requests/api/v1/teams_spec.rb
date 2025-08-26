require 'rails_helper'

RSpec.describe 'Teams API', type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:headers) { auth_headers_for(user) }

  before do
    # Ensure user is the owner of the team for all tests
    create(:team_membership, user: user, team: team, role: :owner)
  end

  describe 'GET /api/v1/teams' do
    it 'returns a list of teams' do
      get '/api/v1/teams', headers: headers
      expect(response).to have_http_status(:ok)
      # Ensure the returned teams include the one the user owns
      json = JSON.parse(response.body)
      expect(json['data'].any? { |t| t['id'] == team.id }).to be true
    end
  end

  describe 'POST /api/v1/teams' do
    let(:valid_params) { { team: { name: 'New Team', description: 'New team description' } } }

    it 'creates a new team and assigns the user as owner' do
      expect {
        post '/api/v1/teams', params: valid_params, headers: headers
      }.to change(Team, :count).by(1)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      new_team_id = json['data']['id']
      membership = TeamMembership.find_by(team_id: new_team_id, user_id: user.id)
      expect(membership).not_to be_nil
      expect(membership.role).to eq('owner')
    end
  end

  describe 'GET /api/v1/teams/:id' do
    it 'returns the team details' do
      get "/api/v1/teams/#{team.id}", headers: headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(team.id)
    end
  end
end
