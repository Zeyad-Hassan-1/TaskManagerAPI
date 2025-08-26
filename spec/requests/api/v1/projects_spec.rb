require 'rails_helper'

RSpec.describe "Api::V1::Projects", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:headers) { auth_headers_for(user) }

  before do
    # Create team membership for the user
    create(:team_membership, user: user, team: team, role: :admin)
    # Create project membership for the user
    create(:project_membership, user: user, project: project, role: :owner)
  end

  describe "GET /api/v1/teams/:team_id/projects" do
    it "returns a list of projects for a team" do
      create_list(:project, 3, team: team, owner: user)
      get "/api/v1/teams/#{team.id}/projects", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data'].size).to eq(4) # 3 created + 1 from let
    end

    it "requires team membership" do
      other_team = create(:team)
      get "/api/v1/teams/#{other_team.id}/projects", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "returns a single project" do
      get "/api/v1/projects/#{project.id}", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['id']).to eq(project.id)
      expect(json_response['data']['name']).to eq(project.name)
    end

    it "returns 404 for non-member" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)
      get "/api/v1/projects/#{project.id}", headers: other_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/teams/:team_id/projects" do
    let(:project_params) {
      { project: { name: "New Project", description: "A new project description" } }
    }

    it "creates a new project" do
      expect {
        post "/api/v1/teams/#{team.id}/projects", headers: headers, params: project_params
      }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['name']).to eq("New Project")
      expect(json_response['data']['description']).to eq("A new project description")

      # Verify project membership was created
      new_project = Project.last
      membership = new_project.project_memberships.find_by(user: user)
      expect(membership).not_to be_nil
      expect(membership.role).to eq('owner')
    end

    it "requires team admin access" do
      member_user = create(:user)
      create(:team_membership, user: member_user, team: team, role: :member)
      member_headers = auth_headers_for(member_user)

      post "/api/v1/teams/#{team.id}/projects", headers: member_headers, params: project_params
      expect(response).to have_http_status(:forbidden)
    end

    it "validates project data" do
      invalid_params = { project: { name: "" } }
      post "/api/v1/teams/#{team.id}/projects", headers: headers, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT /api/v1/projects/:id" do
    let(:update_params) { { project: { name: "Updated Project Name" } } }

    it "updates a project" do
      put "/api/v1/projects/#{project.id}", headers: headers, params: update_params
      expect(response).to have_http_status(:success)
      expect(json_response['data']['name']).to eq("Updated Project Name")
    end

    it "requires admin access" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      put "/api/v1/projects/#{project.id}", headers: member_headers, params: update_params
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a project" do
      delete "/api/v1/projects/#{project.id}", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Project deleted successfully")
    end

    it "requires owner access" do
      admin_user = create(:user)
      create(:project_membership, user: admin_user, project: project, role: :admin)
      admin_headers = auth_headers_for(admin_user)

      delete "/api/v1/projects/#{project.id}", headers: admin_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/projects/:id/invite_member" do
    let(:invited_user) { create(:user) }

    it "invites a user to the project" do
      post "/api/v1/projects/#{project.id}/invite_member",
           headers: headers,
           params: { username: invited_user.username, role: "member" }

      expect(response).to have_http_status(:created)
      expect(json_response['data']['message']).to eq("User invited successfully")

      membership = project.project_memberships.find_by(user: invited_user)
      expect(membership).not_to be_nil
      expect(membership.role).to eq('member')
    end

    it "defaults to member role" do
      post "/api/v1/projects/#{project.id}/invite_member",
           headers: headers,
           params: { username: invited_user.username }

      expect(response).to have_http_status(:created)
      membership = project.project_memberships.find_by(user: invited_user)
      expect(membership.role).to eq('member')
    end

    it "validates user exists" do
      post "/api/v1/projects/#{project.id}/invite_member",
           headers: headers,
           params: { username: "nonexistent" }

      expect(response).to have_http_status(:not_found)
    end

    it "prevents duplicate invitations" do
      create(:project_membership, user: invited_user, project: project, role: :member)

      post "/api/v1/projects/#{project.id}/invite_member",
           headers: headers,
           params: { username: invited_user.username }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/projects/:id/members/:user_id" do
    let(:member_user) { create(:user) }

    before do
      create(:project_membership, user: member_user, project: project, role: :member)
    end

    it "removes a member" do
      delete "/api/v1/projects/#{project.id}/members/#{member_user.id}", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Member removed successfully")

      membership = project.project_memberships.find_by(user: member_user)
      expect(membership).to be_nil
    end

    it "prevents removing the owner" do
      delete "/api/v1/projects/#{project.id}/members/#{user.id}", headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT /api/v1/projects/:id/members/:user_id/promote" do
    let(:member_user) { create(:user) }

    before do
      create(:project_membership, user: member_user, project: project, role: :member)
    end

    it "promotes a member to admin" do
      put "/api/v1/projects/#{project.id}/members/#{member_user.id}/promote", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Member promoted to admin successfully")

      membership = project.project_memberships.find_by(user: member_user)
      expect(membership.role).to eq('admin')
    end

    it "prevents promoting the owner" do
      put "/api/v1/projects/#{project.id}/members/#{user.id}/promote", headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PUT /api/v1/projects/:id/members/:user_id/demote" do
    let(:admin_user) { create(:user) }

    before do
      create(:project_membership, user: admin_user, project: project, role: :admin)
    end

    it "demotes an admin to member" do
      put "/api/v1/projects/#{project.id}/members/#{admin_user.id}/demote", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Admin demoted to member successfully")

      membership = project.project_memberships.find_by(user: admin_user)
      expect(membership.role).to eq('member')
    end

    it "prevents demoting the owner" do
      put "/api/v1/projects/#{project.id}/members/#{user.id}/demote", headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
