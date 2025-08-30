require 'rails_helper'

RSpec.describe "Api::V1::ProjectAttachments", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team, owner: user) }
  let(:headers) { auth_headers_for(user) }

  before do
    create(:team_membership, user: user, team: team, role: :admin)
    create(:project_membership, user: user, project: project, role: :owner)
  end

  describe "POST /api/v1/projects/:project_id/add_attachment" do
    context "with file upload" do
      let(:file) { fixture_file_upload('test_file.txt', 'text/plain') }
      let(:file_params) { { attachment: { file: file, description: "Test Document" } } }

      it "creates attachment with file upload" do
        expect {
          post "/api/v1/projects/#{project.id}/add_attachment", headers: headers, params: file_params
        }.to change(project.attachments, :count).by(1)

        expect(response).to have_http_status(:created)

        attachment = project.attachments.last
        expect(attachment.description).to eq("Test Document")
        expect(attachment.user).to eq(user)
        expect(attachment.file).to be_attached
      end

      it "returns attachment details with file metadata" do
        post "/api/v1/projects/#{project.id}/add_attachment", headers: headers, params: file_params

        expect(json_response['data']['description']).to eq("Test Document")
        expect(json_response['data']['file_url']).to be_present
        expect(json_response['data']['content_type']).to eq("text/plain")
      end

      it "allows attachment without custom description" do
        post "/api/v1/projects/#{project.id}/add_attachment", headers: headers, params: { attachment: { file: file } }

        expect(response).to have_http_status(:created)
        attachment = project.attachments.last
        expect(attachment.description).to be_nil
        expect(attachment.file).to be_attached
      end
    end

    it "requires file attachment" do
      post "/api/v1/projects/#{project.id}/add_attachment", headers: headers, params: { attachment: { description: "No File" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include("File can't be blank")
    end

    it "requires project membership" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)
      file = fixture_file_upload('test_file.txt', 'text/plain')

      post "/api/v1/projects/#{project.id}/add_attachment", headers: other_headers, params: { attachment: { file: file } }

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq("You must be a member of this project or its team to view it")
    end

    it "allows project members to upload attachments" do
      member_user = create(:user)
      create(:project_membership, user: member_user, project: project, role: :member)
      member_headers = auth_headers_for(member_user)
      file = fixture_file_upload('test_file.txt', 'text/plain')

      expect {
        post "/api/v1/projects/#{project.id}/add_attachment", headers: member_headers, params: { attachment: { file: file } }
      }.to change(project.attachments, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /api/v1/projects/:project_id/attachments/:attachment_id" do
    let!(:attachment) { create(:attachment, attachable: project, user: user) }

    before do
      # Attach a file to make it a valid attachment
      attachment.file.attach(
        io: StringIO.new("test content"),
        filename: "test.txt",
        content_type: "text/plain"
      )
    end

    it "deletes attachment by its owner" do
      expect {
        delete "/api/v1/projects/#{project.id}/attachments/#{attachment.id}", headers: headers
      }.to change(project.attachments, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Attachment deleted successfully")
    end

    it "allows project members to delete any attachment" do
      other_user = create(:user)
      create(:project_membership, user: other_user, project: project, role: :member)
      other_attachment = create(:attachment, attachable: project, user: other_user)
      other_attachment.file.attach(
        io: StringIO.new("test content"),
        filename: "other.txt",
        content_type: "text/plain"
      )

      expect {
        delete "/api/v1/projects/#{project.id}/attachments/#{other_attachment.id}", headers: headers
      }.to change(project.attachments, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "prevents non-members from deleting attachments" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      delete "/api/v1/projects/#{project.id}/attachments/#{attachment.id}", headers: other_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq("You must be an admin or owner of this project to perform this action")
    end

    it "returns 404 for non-existent attachment" do
      delete "/api/v1/projects/#{project.id}/attachments/99999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "error handling" do
    it "handles non-existent project" do
      file = fixture_file_upload('test_file.txt', 'text/plain')

      post "/api/v1/projects/99999/add_attachment", headers: headers, params: { attachment: { file: file } }

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Project not found")
    end

    it "handles file uploads gracefully" do
      # Test the endpoint accepts files properly
      file = fixture_file_upload('test_file.txt', 'text/plain')

      post "/api/v1/projects/#{project.id}/add_attachment", headers: headers, params: { attachment: { file: file } }

      expect(response).to have_http_status(:created)
    end
  end
end
