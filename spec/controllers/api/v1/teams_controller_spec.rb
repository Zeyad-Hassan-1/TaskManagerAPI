require 'rails_helper'

RSpec.describe Api::V1::TeamsController, type: :controller do
  let(:user) { create(:user, username: 'testuser1') }
  let(:member_user) { create(:user, username: 'testuser2') }
  let(:admin_user) { create(:user, username: 'testuser3') }
  let(:owner_user) { create(:user, username: 'testuser4') }
  let(:team) { create(:team, name: 'Test Team', discription: 'Test team description') }

  before do
    # Set up team memberships
    create(:team_membership, user: user, team: team, role: :member)
    create(:team_membership, user: member_user, team: team, role: :member)
    create(:team_membership, user: admin_user, team: team, role: :admin)
    create(:team_membership, user: owner_user, team: team, role: :owner)

    # Mock authentication
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:authorized).and_return(true)
  end

  describe 'GET #index' do
    it 'returns a list of user teams' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #show' do
    context 'when user is a member of the team' do
      before { allow(controller).to receive(:current_user).and_return(member_user) }

      it 'returns the team details' do
        get :show, params: { id: team.id }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not a member of the team' do
      let(:non_member) { create(:user, username: 'nonmember') }

      before { allow(controller).to receive(:current_user).and_return(non_member) }

      it 'returns forbidden status' do
        get :show, params: { id: team.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) { { team: { name: 'New Team', discription: 'New team description' } } }

    it 'creates a new team' do
      expect {
        post :create, params: valid_params
      }.to change(Team, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'creates team membership for creator as owner' do
      post :create, params: valid_params
      team = Team.last
      membership = team.team_memberships.find_by(user: user)
      expect(membership.role).to eq('owner')
    end
  end

  describe 'POST #invite_member' do
    let(:new_user) { create(:user, username: 'newuser') }
    let(:invite_params) { { id: team.id, username: 'newuser', role: 'member' } }

    context 'when user is admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'invites a new member' do
        expect {
          post :invite_member, params: invite_params
        }.to change(TeamMembership, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'invites with admin role' do
        post :invite_member, params: { id: team.id, username: 'newuser', role: 'admin' }
        membership = team.team_memberships.find_by(user: new_user)
        expect(membership.role).to eq('admin')
      end
    end

    context 'when user is owner' do
      before { allow(controller).to receive(:current_user).and_return(owner_user) }

      it 'invites a new member' do
        expect {
          post :invite_member, params: invite_params
        }.to change(TeamMembership, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when user is member' do
      before { allow(controller).to receive(:current_user).and_return(member_user) }

      it 'returns forbidden status' do
        post :invite_member, params: invite_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user does not exist' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'returns not found status' do
        post :invite_member, params: { id: team.id, username: 'nonexistent', role: 'member' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT #promote_member' do
    let(:promote_params) { { id: team.id, user_id: member_user.id } }

    context 'when user is owner' do
      before { allow(controller).to receive(:current_user).and_return(owner_user) }

      it 'promotes member to admin' do
        put :promote_member, params: promote_params
        expect(response).to have_http_status(:success)
        member_user.reload
        membership = team.team_memberships.find_by(user: member_user)
        expect(membership.role).to eq('admin')
      end
    end

    context 'when user is admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'returns forbidden status' do
        put :promote_member, params: promote_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT #demote_member' do
    let(:demote_params) { { id: team.id, user_id: admin_user.id } }

    context 'when user is owner' do
      before { allow(controller).to receive(:current_user).and_return(owner_user) }

      it 'demotes admin to member' do
        put :demote_member, params: demote_params
        expect(response).to have_http_status(:success)
        admin_user.reload
        membership = team.team_memberships.find_by(user: admin_user)
        expect(membership.role).to eq('member')
      end
    end

    context 'when user is admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'returns forbidden status' do
        put :demote_member, params: demote_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #remove_member' do
    let(:remove_params) { { id: team.id, user_id: member_user.id } }

    context 'when user is owner' do
      before { allow(controller).to receive(:current_user).and_return(owner_user) }

      it 'removes member from team' do
        expect {
          delete :remove_member, params: remove_params
        }.to change(TeamMembership, :count).by(-1)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'returns forbidden status' do
        delete :remove_member, params: remove_params
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user is owner' do
      before { allow(controller).to receive(:current_user).and_return(owner_user) }

      it 'deletes the team' do
        expect {
          delete :destroy, params: { id: team.id }
        }.to change(Team, :count).by(-1)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is admin' do
      before { allow(controller).to receive(:current_user).and_return(admin_user) }

      it 'returns forbidden status' do
        delete :destroy, params: { id: team.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
