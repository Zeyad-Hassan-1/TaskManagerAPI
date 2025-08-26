require 'rails_helper'

RSpec.describe "Api::V1::TaskComments", type: :request do
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

  describe "POST /api/v1/tasks/:task_id/comments" do
    let(:comment_params) { { content: "This is a task comment" } }

    it "creates a new comment on the task" do
      expect {
        post "/api/v1/tasks/#{task.id}/comments", headers: headers, params: comment_params
      }.to change(task.comments, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['content']).to eq("This is a task comment")
      expect(json_response['data']['user_id']).to eq(user.id)
    end

    it "requires content" do
      post "/api/v1/tasks/#{task.id}/comments", headers: headers, params: { content: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires task membership or project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      post "/api/v1/tasks/#{task.id}/comments", headers: other_headers, params: comment_params
      expect(response).to have_http_status(:forbidden)
    end

    it "allows task assignees to comment" do
      member_user = create(:user)
      create(:task_membership, user: member_user, task: task, role: :assignee)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/tasks/#{task.id}/comments", headers: member_headers, params: comment_params
      }.to change(task.comments, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "allows project members to comment on tasks" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/tasks/#{task.id}/comments", headers: member_headers, params: comment_params
      }.to change(task.comments, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT /api/v1/tasks/:task_id/comments/:id" do
    let!(:comment) { create(:comment, commentable: task, user: user) }
    let(:update_params) { { content: "Updated task comment" } }

    it "updates the comment by its owner" do
      put "/api/v1/tasks/#{task.id}/comments/#{comment.id}", headers: headers, params: update_params

      expect(response).to have_http_status(:success)
      expect(json_response['data']['content']).to eq("Updated task comment")
      expect(comment.reload.content).to eq("Updated task comment")
    end

    it "allows project owner to update any comment" do
      other_user = create(:user)
      create(:task_membership, user: other_user, task: task, role: :assignee)
      other_comment = create(:comment, commentable: task, user: other_user)

      put "/api/v1/tasks/#{task.id}/comments/#{other_comment.id}", headers: headers, params: update_params

      expect(response).to have_http_status(:success)
      expect(json_response['data']['content']).to eq("Updated task comment")
    end

    it "prevents non-authorized users from updating comments" do
      other_user = create(:user)
      member_user = create(:user)
      create(:task_membership, user: other_user, task: task, role: :assignee)
      create(:task_membership, user: member_user, task: task, role: :assignee)

      other_comment = create(:comment, commentable: task, user: other_user)
      member_headers = auth_headers_for(member_user)

      put "/api/v1/tasks/#{task.id}/comments/#{other_comment.id}", headers: member_headers, params: update_params

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/tasks/:task_id/comments/:id" do
    let!(:comment) { create(:comment, commentable: task, user: user) }

    it "deletes the comment by its owner" do
      expect {
        delete "/api/v1/tasks/#{task.id}/comments/#{comment.id}", headers: headers
      }.to change(task.comments, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Comment removed successfully")
    end

    it "allows project owner to delete any comment" do
      other_user = create(:user)
      create(:task_membership, user: other_user, task: task, role: :assignee)
      other_comment = create(:comment, commentable: task, user: other_user)

      expect {
        delete "/api/v1/tasks/#{task.id}/comments/#{other_comment.id}", headers: headers
      }.to change(task.comments, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "prevents non-authorized users from deleting comments" do
      other_user = create(:user)
      member_user = create(:user)
      create(:task_membership, user: other_user, task: task, role: :assignee)
      create(:task_membership, user: member_user, task: task, role: :assignee)

      other_comment = create(:comment, commentable: task, user: other_user)
      member_headers = auth_headers_for(member_user)

      delete "/api/v1/tasks/#{task.id}/comments/#{other_comment.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent comment" do
      delete "/api/v1/tasks/#{task.id}/comments/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
