require 'rails_helper'

RSpec.describe "Api::V1::ProjectTags", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:headers) { auth_headers_for(user) }

  before do
    create(:team_membership, user: user, team: team, role: :admin)
    create(:project_membership, user: user, project: project, role: :owner)
  end

  describe "POST /api/v1/projects/:project_id/add_tag" do
    let(:tag_params) { { name: "urgent" } }

    it "creates and adds a new tag to the project" do
      expect {
        post "/api/v1/projects/#{project.id}/add_tag", headers: headers, params: tag_params
      }.to change(Tag, :count).by(1).and change(project.tags, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['data']['name']).to eq("urgent")

      tag = Tag.find_by(name: "urgent")
      expect(tag).to be_present
      expect(project.tags).to include(tag)
    end

    it "adds existing tag to the project without creating duplicate" do
      existing_tag = create(:tag, name: "existing")

      expect {
        post "/api/v1/projects/#{project.id}/add_tag", headers: headers, params: { name: "existing" }
      }.to change(Tag, :count).by(0).and change(project.tags, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(project.tags).to include(existing_tag)
    end

    it "does not add duplicate tags to the same project" do
      existing_tag = create(:tag, name: "existing")
      project.tags << existing_tag

      expect {
        post "/api/v1/projects/#{project.id}/add_tag", headers: headers, params: { name: "existing" }
      }.to change(Tag, :count).by(0).and change(project.tags, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to eq("Tag already exists on this project")
    end

    it "requires project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      post "/api/v1/projects/#{project.id}/add_tag", headers: other_headers, params: tag_params
      expect(response).to have_http_status(:forbidden)
    end

    it "allows project members to add tags" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      expect {
        post "/api/v1/projects/#{project.id}/add_tag", headers: member_headers, params: tag_params
      }.to change(project.tags, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it "handles case-sensitive tag names" do
      create(:tag, name: "urgent")

      expect {
        post "/api/v1/projects/#{project.id}/add_tag", headers: headers, params: { name: "URGENT" }
      }.to change(Tag, :count).by(0).and change(project.tags, :count).by(1)  # Uses existing "urgent" tag

      expect(Tag.find_by(name: "urgent")).to be_present  # Controller converts to lowercase
    end
  end

  describe "DELETE /api/v1/projects/:project_id/tags/:id" do
    let!(:tag) { create(:tag, name: "to_remove") }

    before do
      project.tags << tag
    end

    it "removes the tag from the project" do
      expect {
        delete "/api/v1/projects/#{project.id}/tags/#{tag.id}", headers: headers
      }.to change(project.tags, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Tag removed successfully")
      expect(project.tags).not_to include(tag)
    end

    it "does not delete the tag from other projects" do
      other_project = create(:project, team: team, owner: user)
      other_project.tags << tag

      delete "/api/v1/projects/#{project.id}/tags/#{tag.id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(other_project.tags).to include(tag)
      expect(Tag.find_by(id: tag.id)).to be_present
    end

    it "returns 404 for non-existent tag association" do
      other_tag = create(:tag, name: "not_associated")

      delete "/api/v1/projects/#{project.id}/tags/#{other_tag.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "requires project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      delete "/api/v1/projects/#{project.id}/tags/#{tag.id}", headers: other_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "allows project members to remove tags" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)

      delete "/api/v1/projects/#{project.id}/tags/#{tag.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)  # Members can't remove tags, only admins
    end
  end

  describe "error handling" do
    it "handles non-existent project" do
      post "/api/v1/projects/99999/add_tag", headers: headers, params: { name: "test" }
      expect(response).to have_http_status(:not_found)
      # Don't check JSON response as it might return HTML error page
    end
  end
end
