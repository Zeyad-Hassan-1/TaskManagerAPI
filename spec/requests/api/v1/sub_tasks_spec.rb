require 'rails_helper'

RSpec.describe "Api::V1::SubTasks", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:parent_task) { create(:task, project: project) }
  let(:headers) { auth_headers_for(user) }

  before do
    create(:team_membership, user: user, team: team, role: :admin)
    create(:project_membership, user: user, project: project, role: :owner)
    create(:task_membership, user: user, task: parent_task, role: :assignee)
  end

  describe "GET /api/v1/tasks/:task_id/sub_tasks" do
    let!(:sub_task1) { create(:task, project: project, parent: parent_task) }
    let!(:sub_task2) { create(:task, project: project, parent: parent_task) }
    let!(:other_task) { create(:task, project: project) } # Not a sub-task

    it "returns all sub-tasks for the parent task" do
      get "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers

      expect(response).to have_http_status(:success)
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(2)

      sub_task_ids = json_response['data'].map { |task| task['id'] }
      expect(sub_task_ids).to contain_exactly(sub_task1.id, sub_task2.id)
    end

    it "returns empty array when parent task has no sub-tasks" do
      task_without_subtasks = create(:task, project: project)
      create(:task_membership, user: user, task: task_without_subtasks, role: :assignee)

      get "/api/v1/tasks/#{task_without_subtasks.id}/sub_tasks", headers: headers

      expect(response).to have_http_status(:success)
      expect(json_response['data']).to eq([])
    end

    it "requires access to parent task" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      get "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: other_headers

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Parent task not found")
    end

    it "returns 404 for non-existent parent task" do
      get "/api/v1/tasks/99999/sub_tasks", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Parent task not found")
    end
  end

  describe "POST /api/v1/tasks/:task_id/sub_tasks" do
    let(:valid_params) do
      {
        task: {
          name: "Sub-task Name",
          description: "Sub-task description",
          priority: :medium,
          due_date: 3.days.from_now
        }
      }
    end

    it "creates a sub-task successfully" do
      expect {
        post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: valid_params
      }.to change(Task, :count).by(1).and change(TaskMembership, :count).by(1)

      expect(response).to have_http_status(:created)

      sub_task = Task.last
      expect(sub_task.parent).to eq(parent_task)
      expect(sub_task.project).to eq(project)
      expect(sub_task.name).to eq("Sub-task Name")
      expect(sub_task.description).to eq("Sub-task description")
    end

    it "automatically assigns creator as task member" do
      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: valid_params

      sub_task = Task.last
      membership = sub_task.task_memberships.find_by(user: user)
      expect(membership).to be_present
      expect(membership.role).to eq('assignee')
    end

    it "inherits project from parent task" do
      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: valid_params

      sub_task = Task.last
      expect(sub_task.project_id).to eq(parent_task.project_id)
    end

    it "requires project admin or owner permissions" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      create(:task_membership, user: member_user, task: parent_task, role: :assignee)
      member_headers = auth_headers_for(member_user)

      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: member_headers, params: valid_params

      expect(response).to have_http_status(:forbidden)
      expect(json_response['message']).to eq("You must be an admin or owner of the project to create tasks")
    end

    it "allows project admin to create sub-tasks" do
      admin_user = create(:user)
      create(:project_membership, user: admin_user, project: project, role: :admin)
      create(:task_membership, user: admin_user, task: parent_task, role: :assignee)
      admin_headers = auth_headers_for(admin_user)

      expect {
        post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: admin_headers, params: valid_params
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "requires task name" do
      invalid_params = valid_params.deep_merge(task: { name: "" })

      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include("Name can't be blank")
    end

    it "validates priority enum" do
      invalid_params = valid_params.deep_merge(task: { priority: "invalid" })

      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include("Priority")
    end

    it "handles due_date properly" do
      future_date = 5.days.from_now
      params_with_date = valid_params.deep_merge(task: { due_date: future_date })

      post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: params_with_date

      expect(response).to have_http_status(:created)
      sub_task = Task.last
      expect(sub_task.due_date.to_date).to eq(future_date.to_date)
    end

    it "allows optional description" do
      minimal_params = { task: { name: "Minimal Sub-task" } }

      expect {
        post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: minimal_params
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      sub_task = Task.last
      expect(sub_task.description).to be_nil
    end

    it "creates sub-task within transaction" do
      allow_any_instance_of(Task).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Task.new))

      expect {
        post "/api/v1/tasks/#{parent_task.id}/sub_tasks", headers: headers, params: valid_params
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/sub_tasks/:id" do
    let(:sub_task) { create(:task, project: project, parent: parent_task) }

    before do
      create(:task_membership, user: user, task: sub_task, role: :assignee)
    end

    it "shows sub-task details" do
      get "/api/v1/sub_tasks/#{sub_task.id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(json_response['data']['id']).to eq(sub_task.id)
      expect(json_response['data']['name']).to eq(sub_task.name)
      expect(json_response['data']['parent_id']).to eq(parent_task.id)
    end

    it "requires task membership or project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      get "/api/v1/sub_tasks/#{sub_task.id}", headers: other_headers

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Sub-task not found")
    end

    it "allows project members to view sub-tasks" do
      project_member = create(:user)
      create(:project_membership, user: project_member, project: project, role: :member)
      member_headers = auth_headers_for(project_member)

      get "/api/v1/sub_tasks/#{sub_task.id}", headers: member_headers

      expect(response).to have_http_status(:success)
    end
  end

  describe "PUT /api/v1/sub_tasks/:id" do
    let(:sub_task) { create(:task, project: project, parent: parent_task, name: "Original Name") }
    let(:update_params) { { task: { name: "Updated Sub-task Name" } } }

    before do
      create(:task_membership, user: user, task: sub_task, role: :assignee)
    end

    it "updates sub-task successfully" do
      put "/api/v1/sub_tasks/#{sub_task.id}", headers: headers, params: update_params

      expect(response).to have_http_status(:success)
      expect(json_response['data']['name']).to eq("Updated Sub-task Name")

      sub_task.reload
      expect(sub_task.name).to eq("Updated Sub-task Name")
    end

    it "requires admin access to update" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      create(:task_membership, user: member_user, task: sub_task, role: :assignee)
      member_headers = auth_headers_for(member_user)

      put "/api/v1/sub_tasks/#{sub_task.id}", headers: member_headers, params: update_params

      expect(response).to have_http_status(:forbidden)
      expect(json_response['message']).to eq("You must be an admin or owner of this project to perform this action")
    end

    it "validates updated fields" do
      invalid_params = { task: { name: "" } }

      put "/api/v1/sub_tasks/#{sub_task.id}", headers: headers, params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include("Name can't be blank")
    end
  end

  describe "DELETE /api/v1/sub_tasks/:id" do
    let(:sub_task) { create(:task, project: project, parent: parent_task) }

    before do
      create(:task_membership, user: user, task: sub_task, role: :assignee)
    end

    it "deletes sub-task successfully" do
      expect {
        delete "/api/v1/sub_tasks/#{sub_task.id}", headers: headers
      }.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Task deleted successfully")
    end

    it "requires owner access to delete" do
      admin_user = create(:user)
      create(:project_membership, user: admin_user, project: project, role: :admin)
      create(:task_membership, user: admin_user, task: sub_task, role: :assignee)
      admin_headers = auth_headers_for(admin_user)

      delete "/api/v1/sub_tasks/#{sub_task.id}", headers: admin_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response['message']).to eq("You must be the owner of this project to delete tasks")
    end
  end
end
