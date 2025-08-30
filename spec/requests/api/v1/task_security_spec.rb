require 'rails_helper'

RSpec.describe "Api::V1::Tasks - Enhanced Security", type: :request do
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }

  # Users with different roles
  let(:project_owner) { create(:user) }
  let(:project_admin) { create(:user) }
  let(:project_member) { create(:user) }
  let(:task_assignee) { create(:user) }
  let(:outside_user) { create(:user) }

  before do
    # Setup project roles
    create(:team_membership, user: project_owner, team: team, role: :admin)
    create(:project_membership, user: project_owner, project: project, role: :owner)

    create(:team_membership, user: project_admin, team: team, role: :member)
    create(:project_membership, user: project_admin, project: project, role: :admin)

    create(:team_membership, user: project_member, team: team, role: :member)
    create(:project_membership, user: project_member, project: project, role: :member)

    create(:team_membership, user: task_assignee, team: team, role: :member)
    create(:project_membership, user: task_assignee, project: project, role: :member)
    create(:task_membership, user: task_assignee, task: task, role: :assignee)
  end

  describe "POST /api/v1/tasks/:id/assign_member" do
    let(:target_user) { project_member }
    let(:assign_params) { { username: target_user.username, role: "assignee" } }

    context "with project owner" do
      let(:headers) { auth_headers_for(project_owner) }

      it "allows assigning members" do
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: assign_params

        expect(response).to have_http_status(:created)
        expect(json_response['data']['message']).to eq("User assigned to task successfully")
        expect(task.task_memberships.where(user: target_user)).to exist
      end

      it "accepts valid roles" do
        %w[assignee reviewer watcher].each do |role|
          user_for_role = create(:user)
          create(:project_membership, user: user_for_role, project: project, role: :member)
          params = { username: user_for_role.username, role: role }

          post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: params

          expect(response).to have_http_status(:created)
          expect(task.task_memberships.find_by(user: user_for_role).role).to eq(role)
        end
      end

      it "rejects invalid roles" do
        params = { username: target_user.username, role: "invalid_role" }

        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: params

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to include("Invalid role")
      end

      it "replaces existing membership with new role" do
        # First assignment
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: assign_params
        expect(task.task_memberships.where(user: target_user).first.role).to eq("assignee")

        # Reassign with different role should fail because user is already a member
        new_params = { username: target_user.username, role: "reviewer" }
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: new_params

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("User is already a member of this task")
      end

      it "prevents assigning users not in project" do
        params = { username: outside_user.username, role: "assignee" }

        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: params

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("User must be a member of the project to be assigned to tasks")
      end

      it "handles non-existent username" do
        params = { username: "nonexistent_user", role: "assignee" }

        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: params

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq("User not found")
      end
    end

    context "with project admin" do
      let(:headers) { auth_headers_for(project_admin) }

      it "allows assigning members" do
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: assign_params

        expect(response).to have_http_status(:created)
        expect(json_response['data']['message']).to eq("User assigned to task successfully")
      end
    end

    context "with project member (not admin)" do
      let(:headers) { auth_headers_for(project_member) }

      it "prevents assigning members" do
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: assign_params

        expect(response).to have_http_status(:forbidden)
        expect(json_response['message']).to eq("You must be an admin or owner of this project to perform this action")
      end
    end

    context "with outside user" do
      let(:headers) { auth_headers_for(outside_user) }

      it "prevents access completely" do
        post "/api/v1/tasks/#{task.id}/assign_member", headers: headers, params: assign_params

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq("Task not found")
      end
    end
  end

  describe "DELETE /api/v1/tasks/:id/members/:user_id" do
    let!(:task_member) { create(:user) }

    before do
      create(:project_membership, user: task_member, project: project, role: :member)
      create(:task_membership, user: task_member, task: task, role: :assignee)
    end

    context "with project owner removing regular member" do
      let(:headers) { auth_headers_for(project_owner) }

      it "allows removal" do
        expect {
          delete "/api/v1/tasks/#{task.id}/members/#{task_member.id}", headers: headers
        }.to change { task.task_memberships.count }.by(-1)

        expect(response).to have_http_status(:success)
        expect(json_response['data']['message']).to eq("User removed from task successfully")
      end
    end

    context "with project admin removing regular member" do
      let(:headers) { auth_headers_for(project_admin) }

      it "allows removal" do
        expect {
          delete "/api/v1/tasks/#{task.id}/members/#{task_member.id}", headers: headers
        }.to change { task.task_memberships.count }.by(-1)

        expect(response).to have_http_status(:success)
      end
    end

    context "project owner trying to remove themselves" do
      let(:headers) { auth_headers_for(project_owner) }

      before do
        create(:task_membership, user: project_owner, task: task, role: :assignee)
      end

      it "prevents self-removal" do
        delete "/api/v1/tasks/#{task.id}/members/#{project_owner.id}", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Project owners cannot remove themselves from tasks")
      end
    end

    context "admin trying to remove project owner" do
      let(:headers) { auth_headers_for(project_admin) }

      before do
        create(:task_membership, user: project_owner, task: task, role: :assignee)
      end

      it "prevents removal" do
        delete "/api/v1/tasks/#{task.id}/members/#{project_owner.id}", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Only project owners can remove other owners or admins from tasks")
      end
    end

    context "admin trying to remove another admin" do
      let(:headers) { auth_headers_for(project_admin) }
      let(:another_admin) { create(:user) }

      before do
        create(:project_membership, user: another_admin, project: project, role: :admin)
        create(:task_membership, user: another_admin, task: task, role: :reviewer)
      end

      it "prevents removal" do
        delete "/api/v1/tasks/#{task.id}/members/#{another_admin.id}", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Only project owners can remove other owners or admins from tasks")
      end
    end

    context "owner removing admin" do
      let(:headers) { auth_headers_for(project_owner) }

      before do
        create(:task_membership, user: project_admin, task: task, role: :reviewer)
      end

      it "allows removal" do
        expect {
          delete "/api/v1/tasks/#{task.id}/members/#{project_admin.id}", headers: headers
        }.to change { task.task_memberships.count }.by(-1)

        expect(response).to have_http_status(:success)
      end
    end

    context "user removing themselves" do
      let(:headers) { auth_headers_for(task_member) }

      it "prevents self-removal when not admin" do
        delete "/api/v1/tasks/#{task.id}/members/#{task_member.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response['message']).to eq("You must be an admin or owner of this project to perform this action")
      end
    end

    context "removing the only assignee" do
      let(:headers) { auth_headers_for(project_owner) }
      let(:only_assignee) { create(:user) }

      before do
        # Clear existing task memberships
        task.task_memberships.destroy_all

        # Create only one assignee
        create(:project_membership, user: only_assignee, project: project, role: :member)
        create(:task_membership, user: only_assignee, task: task, role: :assignee)
      end

      it "prevents removal" do
        delete "/api/v1/tasks/#{task.id}/members/#{only_assignee.id}", headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to eq("Cannot remove the only assignee from a task")
        expect(task.task_memberships.count).to eq(1)
      end
    end

    context "with regular member trying to remove others" do
      let(:headers) { auth_headers_for(project_member) }

      it "prevents removal" do
        delete "/api/v1/tasks/#{task.id}/members/#{task_member.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response['message']).to eq("You must be an admin or owner of this project to perform this action")
      end
    end

    context "with non-existent user" do
      let(:headers) { auth_headers_for(project_owner) }

      it "returns 404" do
        delete "/api/v1/tasks/#{task.id}/members/99999", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with user not assigned to task" do
      let(:headers) { auth_headers_for(project_owner) }
      let(:unassigned_user) { create(:user) }

      before do
        create(:project_membership, user: unassigned_user, project: project, role: :member)
      end

      it "returns appropriate error" do
        delete "/api/v1/tasks/#{task.id}/members/#{unassigned_user.id}", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq("User is not assigned to this task")
      end
    end
  end

  describe "task visibility with enhanced security" do
    context "viewing tasks" do
      it "allows assigned users to view tasks" do
        headers = auth_headers_for(task_assignee)

        get "/api/v1/tasks/#{task.id}", headers: headers

        expect(response).to have_http_status(:success)
      end

      it "prevents non-assigned project members from viewing" do
        headers = auth_headers_for(project_member)

        get "/api/v1/tasks/#{task.id}", headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(json_response['message']).to eq("You must be assigned to this task to view it")
      end

      it "prevents outside users from viewing" do
        headers = auth_headers_for(outside_user)

        get "/api/v1/tasks/#{task.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
