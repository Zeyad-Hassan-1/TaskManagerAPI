require 'rails_helper'

RSpec.describe "Api::V1::ProjectComments", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:headers) { auth_headers_for(user) }

  before do
    create(:team_membership, user: user, team: team, role: :admin)
    create(:project_membership, user: user, project: project, role: :owner)
  end

  describe "POST /api/v1/projects/:project_id/add_comment" do
    let(:comment_params) { { comment: { content: "This is a test comment" } } }

    it "creates a new comment on the project" do
      expect {
        post "/api/v1/projects/#{project.id}/add_comment", headers: headers, params: comment_params
      }.to change(project.comments, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['content']).to eq("This is a test comment")
    end

    it "requires content" do
      post "/api/v1/projects/#{project.id}/add_comment", headers: headers, params: { comment: { content: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      post "/api/v1/projects/#{project.id}/add_comment", headers: other_headers, params: comment_params
      expect(response).to have_http_status(:forbidden)
    end

    it "allows project members to comment" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/projects/#{project.id}/add_comment", headers: member_headers, params: comment_params
      }.to change(project.comments, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /api/v1/projects/:id/comments/:comment_id" do
    let!(:comment) { create(:comment, commentable: project, user: user) }

    it "deletes the comment by its owner" do
      expect {
        delete "/api/v1/projects/#{project.id}/comments/#{comment.id}", headers: headers
      }.to change(project.comments, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Comment deleted successfully")
    end

    it "allows project owner to delete any comment" do
      other_user = create(:user)
      create(:project_membership, user: other_user, project: project, role: :member)
      other_comment = create(:comment, commentable: project, user: other_user)

      expect {
        delete "/api/v1/projects/#{project.id}/comments/#{other_comment.id}", headers: headers
      }.to change(project.comments, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "prevents non-owners from deleting other users' comments" do
      other_user = create(:user)
      member_user = create(:user)
      create(:project_membership, user: other_user, project: project, role: :member)
      create(:project_membership, user: member_user, project: project, role: :member)

      other_comment = create(:comment, commentable: project, user: other_user)
      member_headers = auth_headers_for(member_user)

      delete "/api/v1/projects/#{project.id}/comments/#{other_comment.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-existent comment" do
      delete "/api/v1/projects/#{project.id}/comments/99999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
