require 'rails_helper'


RSpec.describe "Api::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }
  let(:task) { create(:task, project: project) }
  let(:headers) { auth_headers_for(user) }

  before do
    # Ensure user is a member of the project's team for authorization
    create(:team_membership, user: user, team: project.team, role: :owner)
    create(:project_membership, user: user, project: project, role: :owner)
    create(:task_membership, user: user, task: task, role: :assignee)
  end

  describe "GET /api/v1/projects/:project_id/tasks" do
    it "returns a list of tasks for a project" do
      create_list(:task, 3, project: project)
      get "/api/v1/projects/#{project.id}/tasks", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data'].size).to eq(1) # Only tasks assigned to current user
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "returns a single task" do
      get "/api/v1/tasks/#{task.id}", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['id']).to eq(task.id)
    end
  end

  describe "POST /api/v1/projects/:project_id/tasks" do
    let(:task_params) { { task: { name: "New Task", description: "Task Description", priority: "medium", due_date: 1.week.from_now } } }

    it "creates a new task" do
      post "/api/v1/projects/#{project.id}/tasks", headers: headers, params: task_params
      expect(response).to have_http_status(:created)
      expect(json_response['data']['name']).to eq("New Task")
    end
  end

  describe "PUT /api/v1/tasks/:id" do
    let(:update_params) { { task: { name: "Updated Task Name" } } }

    it "updates a task" do
      put "/api/v1/tasks/#{task.id}", headers: headers, params: update_params
      expect(response).to have_http_status(:success)
      expect(json_response['data']['name']).to eq("Updated Task Name")
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    it "deletes a task" do
      delete "/api/v1/tasks/#{task.id}", headers: headers
      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Task deleted successfully")
    end
  end
end
