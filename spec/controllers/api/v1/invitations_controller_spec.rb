require 'rails_helper'

RSpec.describe Api::V1::InvitationsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team) }
  let(:invitation) { create(:invitation, :for_team, invitee: user, invitable: team) }

  describe 'GET #index' do
    context 'when user has pending invitations' do
      let!(:pending_invitation) { create(:invitation, :for_team, invitee: user, status: 'pending') }
      let!(:accepted_invitation) { create(:invitation, :for_team, invitee: user, status: 'accepted') }

      it 'returns only pending invitations' do
        get '/api/v1/invitations', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        response_data = json_response
        expect(response_data['data'].length).to eq(1)
        expect(response_data['data'].first['id']).to eq(pending_invitation.id)
      end
    end

    context 'when user has no pending invitations' do
      it 'returns empty array' do
        get '/api/v1/invitations', headers: auth_headers_for(user)

        expect(response).to have_http_status(:success)
        expect(json_response['data']).to eq([])
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid status' do
      context 'when accepting invitation' do
        it 'updates invitation status to accepted' do
          put "/api/v1/invitations/#{invitation.id}",
              params: { status: 'accepted' },
              headers: auth_headers_for(user)

          expect(response).to have_http_status(:success)
          expect(json_response['data']['message']).to include('accepted')
          expect(invitation.reload.status).to eq('accepted')
        end

        it 'creates team membership for team invitation' do
          team_invitation = create(:invitation, :for_team, invitee: user, invitable: team)

          expect {
            put "/api/v1/invitations/#{team_invitation.id}",
                params: { status: 'accepted' },
                headers: auth_headers_for(user)
          }.to change(TeamMembership, :count).by(1)

          membership = TeamMembership.last
          expect(membership.user).to eq(user)
          expect(membership.team).to eq(team)
          expect(membership.role).to eq(team_invitation.role)
        end

        it 'creates project membership for project invitation' do
          project = create(:project)
          project_invitation = create(:invitation, :for_project, invitee: user, invitable: project)

          expect {
            put "/api/v1/invitations/#{project_invitation.id}",
                params: { status: 'accepted' },
                headers: auth_headers_for(user)
          }.to change(ProjectMembership, :count).by(1)

          membership = ProjectMembership.last
          expect(membership.user).to eq(user)
          expect(membership.project).to eq(project)
          expect(membership.role).to eq(project_invitation.role)
        end
      end

      context 'when declining invitation' do
        it 'updates invitation status to declined' do
          put "/api/v1/invitations/#{invitation.id}",
              params: { status: 'declined' },
              headers: auth_headers_for(user)

          expect(response).to have_http_status(:success)
          expect(json_response['data']['message']).to include('declined')
          expect(invitation.reload.status).to eq('declined')
        end

        it 'does not create membership' do
          expect {
            put "/api/v1/invitations/#{invitation.id}",
                params: { status: 'declined' },
                headers: auth_headers_for(user)
          }.not_to change(TeamMembership, :count)
        end
      end
    end

    context 'with invalid status' do
      it 'returns error' do
        put "/api/v1/invitations/#{invitation.id}",
            params: { status: 'invalid' },
            headers: auth_headers_for(user)

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']).to include('Status is not included in the list')
      end
    end

    context 'when invitation does not belong to user' do
      let(:other_invitation) { create(:invitation, :for_team, invitee: other_user) }

      it 'returns not found' do
        put "/api/v1/invitations/#{other_invitation.id}",
            params: { status: 'accepted' },
            headers: auth_headers_for(user)

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Invitation not found')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the invitation' do
      invitation_to_delete = create(:invitation, :for_team, invitee: user)

      expect {
        delete "/api/v1/invitations/#{invitation_to_delete.id}",
               headers: auth_headers_for(user)
      }.to change(Invitation, :count).by(-1)

      expect(response).to have_http_status(:success)
      expect(json_response['data']['message']).to eq('Invitation declined.')
    end

    context 'when invitation does not belong to user' do
      let(:other_invitation) { create(:invitation, :for_team, invitee: other_user) }

      it 'returns not found' do
        delete "/api/v1/invitations/#{other_invitation.id}",
               headers: auth_headers_for(user)

        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Invitation not found')
      end
    end
  end
end
