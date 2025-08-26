require 'rails_helper'

RSpec.describe "Api::V1::TaskTags", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:task) { create(:task, project: project) }
  let(:headers) { auth_headers_for(user) }

  before do
    create(:team_membership, user: user, team: team, role: :admin)
    create(:project_membership, user: user, project: project, role: :owner)
    create(:task_membership, user: user, task: task, role: :assignee)
  end

  describe "POST /api/v1/tasks/:task_id/tags" do
    let(:tag_params) { { name: "bug" } }

    it "creates and adds a new tag to the task" do
      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: headers, params: tag_params
      }.to change(Tag, :count).by(1).and change(task.tags, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].first['name']).to eq("bug")

      tag = Tag.find_by(name: "bug")
      expect(tag).to be_present
      expect(task.tags).to include(tag)
    end

    it "adds existing tag to the task without creating duplicate" do
      existing_tag = create(:tag, name: "existing")

      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: headers, params: { name: "existing" }
      }.to change(Tag, :count).by(0).and change(task.tags, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(task.tags).to include(existing_tag)
    end

    it "does not add duplicate tags to the same task" do
      existing_tag = create(:tag, name: "existing")
      task.tags << existing_tag

      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: headers, params: { name: "existing" }
      }.to change(Tag, :count).by(0).and change(task.tags, :count).by(0)

      expect(response).to have_http_status(:success)
      expect(task.tags.where(id: existing_tag.id).count).to eq(1)
    end

    it "requires project membership for task access" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      post "/api/v1/tasks/#{task.id}/tags", headers: other_headers, params: tag_params
      expect(response).to have_http_status(:forbidden)
    end

    it "allows task assignees to add tags" do
      member_user = create(:user)
      create(:task_membership, user: member_user, task: task, role: :assignee)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: member_headers, params: tag_params
      }.to change(task.tags, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it "allows project members to add tags to tasks" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: member_headers, params: tag_params
      }.to change(task.tags, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it "handles case-sensitive tag names" do
      create(:tag, name: "bug")

      expect {
        post "/api/v1/tasks/#{task.id}/tags", headers: headers, params: { name: "BUG" }
      }.to change(Tag, :count).by(1).and change(task.tags, :count).by(1)

      expect(Tag.find_by(name: "BUG")).to be_present
    end
  end

  describe "DELETE /api/v1/tasks/:task_id/tags/:id" do
    let!(:tag) { create(:tag, name: "to_remove") }

    before do
      task.tags << tag
    end

    it "removes the tag from the task" do
      expect {
        delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}", headers: headers
      }.to change(task.tags, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Tag removed successfully")
      expect(task.tags).not_to include(tag)
    end

    it "does not delete the tag from other tasks" do
      other_task = create(:task, project: project)
      other_task.tags << tag

      delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(other_task.tags).to include(tag)
      expect(Tag.find_by(id: tag.id)).to be_present
    end

    it "returns 404 for non-existent tag association" do
      other_tag = create(:tag, name: "not_associated")

      delete "/api/v1/tasks/#{task.id}/tags/#{other_tag.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "requires project membership for task access" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "allows task assignees to remove tags" do
      member_user = create(:user)
      create(:task_membership, user: member_user, task: task, role: :assignee)
      member_headers = auth_headers_for(member_user)

      expect {
        delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}", headers: member_headers
      }.to change(task.tags, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "allows project members to remove tags from tasks" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      expect {
        delete "/api/v1/tasks/#{task.id}/tags/#{tag.id}", headers: member_headers
      }.to change(task.tags, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end

  describe "error handling" do
    it "handles non-existent task" do
      post "/api/v1/tasks/99999/tags", headers: headers, params: { name: "test" }
      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Task not found")
    end
  end
end
