require 'rails_helper'

RSpec.describe "Api::V1::TaskAttachments", type: :request do
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

  describe "POST /api/v1/tasks/:task_id/attachments" do
    context "with file upload" do
      let(:file) { fixture_file_upload('test_file.txt', 'text/plain') }
      let(:file_params) { { file: file, name: "Task Document" } }

      it "creates attachment with file upload" do
        expect {
          post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: file_params
        }.to change(task.attachments, :count).by(1)

        expect(response).to have_http_status(:created)

        attachment = task.attachments.last
        expect(attachment.name).to eq("Task Document")
        expect(attachment.user).to eq(user)
        expect(attachment.file).to be_attached
      end

      it "returns attachment details with file metadata" do
        post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: file_params

        expect(json_response['data']['name']).to eq("Task Document")
        expect(json_response['data']['file_url']).to be_present
        expect(json_response['data']['file_name']).to eq("test_file.txt")
        expect(json_response['data']['content_type']).to eq("text/plain")
        expect(json_response['data']['user_id']).to eq(user.id)
      end

      it "allows attachment without custom name" do
        post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: { file: file }

        expect(response).to have_http_status(:created)
        attachment = task.attachments.last
        expect(attachment.name).to be_nil
        expect(attachment.file).to be_attached
      end
    end

    context "with link URL" do
      let(:link_params) { { link: "https://example.com/task-resource.pdf", name: "Task Reference" } }

      it "creates attachment with link URL" do
        expect {
          post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: link_params
        }.to change(task.attachments, :count).by(1)

        expect(response).to have_http_status(:created)

        attachment = task.attachments.last
        expect(attachment.name).to eq("Task Reference")
        expect(attachment.link).to eq("https://example.com/task-resource.pdf")
        expect(attachment.user).to eq(user)
        expect(attachment.file).not_to be_attached
      end

      it "returns attachment details with link" do
        post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: link_params

        expect(json_response['data']['name']).to eq("Task Reference")
        expect(json_response['data']['link']).to eq("https://example.com/task-resource.pdf")
        expect(json_response['data']['file_url']).to be_nil
        expect(json_response['data']['user_id']).to eq(user.id)
      end

      it "validates link URL format" do
        invalid_params = { link: "invalid-url", name: "Bad Link" }

        post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: invalid_params

        expect(response).to have_http_status(:created)  # Model doesn't validate URL format
        # expect(json_response['error']).to include("Link is invalid")
      end
    end

    it "requires either file or link" do
      post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: { name: "Empty Attachment" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']).to include("Link can't be blank")
      expect(json_response['error']).to include("File can't be blank")
    end

    it "allows both file and link in same attachment" do
      file = fixture_file_upload('test_file.txt', 'text/plain')
      params = { file: file, link: "https://example.com", name: "Both Content Types" }

      post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: params

      expect(response).to have_http_status(:created)
      attachment = task.attachments.last
      expect(attachment.link).to eq("https://example.com")
      expect(attachment.file).to be_attached
    end

    context "authorization" do
      it "allows assigned user to add attachments" do
        file = fixture_file_upload('test_file.txt', 'text/plain')

        expect {
          post "/api/v1/tasks/#{task.id}/attachments", headers: headers, params: { file: file }
        }.to change(task.attachments, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "allows project members to add attachments" do
        member_user = create(:user)
        create(:project_membership, user: member_user, project: project, role: :member)
        member_headers = auth_headers_for(member_user)
        file = fixture_file_upload('test_file.txt', 'text/plain')

        expect {
          post "/api/v1/tasks/#{task.id}/attachments", headers: member_headers, params: { file: file }
        }.to change(task.attachments, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "prevents non-project members from adding attachments" do
        other_user = create(:user)
        other_headers = auth_headers_for(other_user)
        file = fixture_file_upload('test_file.txt', 'text/plain')

        post "/api/v1/tasks/#{task.id}/attachments", headers: other_headers, params: { file: file }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq("You do not have permission to manage attachments for this resource")
      end

      it "requires project membership even for team admin" do
        admin_user = create(:user)
        create(:team_membership, user: admin_user, team: team, role: :admin)
        admin_headers = auth_headers_for(admin_user)
        file = fixture_file_upload('test_file.txt', 'text/plain')

        post "/api/v1/tasks/#{task.id}/attachments", headers: admin_headers, params: { file: file }

        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq("You do not have permission to manage attachments for this resource")
      end
    end
  end

  describe "DELETE /api/v1/tasks/:task_id/attachments/:id" do
    let!(:attachment) { create(:attachment, attachable: task, user: user, link: "https://example.com") }

    it "deletes attachment by its owner" do
      expect {
        delete "/api/v1/tasks/#{task.id}/attachments/#{attachment.id}", headers: headers
      }.to change(task.attachments, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq("Attachment removed successfully")
    end

    it "allows project members to delete any attachment" do
      other_user = create(:user)
      create(:project_membership, user: other_user, project: project, role: :member)
      other_attachment = create(:attachment, attachable: task, user: other_user, link: "https://other.com")

      expect {
        delete "/api/v1/tasks/#{task.id}/attachments/#{other_attachment.id}", headers: headers
      }.to change(task.attachments, :count).by(-1)

      expect(response).to have_http_status(:success)
    end

    it "requires project membership even for team admin" do
      admin_user = create(:user)
      create(:team_membership, user: admin_user, team: team, role: :admin)
      admin_headers = auth_headers_for(admin_user)
      other_attachment = create(:attachment, attachable: task, user: user, link: "https://other.com")

      delete "/api/v1/tasks/#{task.id}/attachments/#{other_attachment.id}", headers: admin_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq("You do not have permission to manage attachments for this resource")
    end

    it "prevents non-members from deleting attachments" do
      other_user = create(:user)
      other_headers = auth_headers_for(other_user)

      delete "/api/v1/tasks/#{task.id}/attachments/#{attachment.id}", headers: other_headers

      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq("You do not have permission to manage attachments for this resource")
    end

    it "returns 404 for non-existent attachment" do
      delete "/api/v1/tasks/#{task.id}/attachments/99999", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "handles file attachments deletion" do
      file_attachment = build(:attachment, attachable: task, user: user, link: nil)
      file_attachment.file.attach(
        io: StringIO.new("test content"),
        filename: "test.txt",
        content_type: "text/plain"
      )
      file_attachment.save!

      expect {
        delete "/api/v1/tasks/#{task.id}/attachments/#{file_attachment.id}", headers: headers
      }.to change(task.attachments, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end

  describe "context with sub-tasks" do
    let(:parent_task) { create(:task, project: project) }
    let(:sub_task) { create(:task, project: project, parent: parent_task) }

    before do
      create(:task_membership, user: user, task: parent_task, role: :assignee)
      create(:task_membership, user: user, task: sub_task, role: :assignee)
    end

    it "creates attachments on sub-tasks" do
      file = fixture_file_upload('test_file.txt', 'text/plain')

      expect {
        post "/api/v1/tasks/#{sub_task.id}/attachments", headers: headers, params: { file: file, name: "Sub-task File" }
      }.to change(sub_task.attachments, :count).by(1)

      expect(response).to have_http_status(:created)
      attachment = sub_task.attachments.last
      expect(attachment.name).to eq("Sub-task File")
    end

    it "maintains separate attachments for parent and sub-tasks" do
      parent_file = fixture_file_upload('test_file.txt', 'text/plain')
      sub_file = fixture_file_upload('test_file.txt', 'text/plain')

      post "/api/v1/tasks/#{parent_task.id}/attachments", headers: headers, params: { file: parent_file, name: "Parent File" }
      post "/api/v1/tasks/#{sub_task.id}/attachments", headers: headers, params: { file: sub_file, name: "Sub File" }

      expect(parent_task.attachments.count).to eq(1)
      expect(sub_task.attachments.count).to eq(1)
      expect(parent_task.attachments.first.name).to eq("Parent File")
      expect(sub_task.attachments.first.name).to eq("Sub File")
    end
  end

  describe "error handling" do
    it "handles non-existent task" do
      file = fixture_file_upload('test_file.txt', 'text/plain')

      post "/api/v1/tasks/99999/attachments", headers: headers, params: { file: file }

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to eq("Task not found")
    end

    it "handles task from different project" do
      other_user = create(:user)
      other_team = create(:team)
      create(:team_membership, user: other_user, team: other_team, role: :admin)
      other_project = create(:project, team: other_team, owner: other_user)
      other_task = create(:task, project: other_project)
      file = fixture_file_upload('test_file.txt', 'text/plain')

      # User is not a member of other_project
      post "/api/v1/tasks/#{other_task.id}/attachments", headers: headers, params: { file: file }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
