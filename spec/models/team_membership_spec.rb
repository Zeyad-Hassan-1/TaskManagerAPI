require 'rails_helper'

RSpec.describe TeamMembership, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  describe 'role enum' do
    it 'has the correct role values' do
      expect(TeamMembership.roles).to eq({
        'member' => 0,
        'admin' => 1,
        'owner' => 2
      })
    end

    it 'defaults to member role' do
      membership = create(:team_membership, user: user, team: team)
      expect(membership.role).to eq('member')
    end

    it 'can be set to admin role' do
      membership = create(:team_membership, user: user, team: team, role: :admin)
      expect(membership.role).to eq('admin')
    end

    it 'can be set to owner role' do
      membership = create(:team_membership, user: user, team: team, role: :owner)
      expect(membership.role).to eq('owner')
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      membership = build(:team_membership, user: user, team: team)
      expect(membership).to be_valid
    end

    it 'requires a user' do
      membership = build(:team_membership, user: nil, team: team)
      expect(membership).not_to be_valid
      expect(membership.errors[:user_id]).to include("can't be blank")
    end

    it 'requires a team' do
      membership = build(:team_membership, user: user, team: nil)
      expect(membership).not_to be_valid
      expect(membership.errors[:team_id]).to include("can't be blank")
    end

    it 'requires a role' do
      membership = build(:team_membership, user: user, team: team, role: nil)
      expect(membership).not_to be_valid
      expect(membership.errors[:role]).to include("can't be blank")
    end
  end

  describe 'role methods' do
    let(:membership) { create(:team_membership, user: user, team: team, role: :member) }

    it 'responds to member?' do
      expect(membership).to respond_to(:member?)
    end

    it 'responds to admin?' do
      expect(membership).to respond_to(:admin?)
    end

    it 'responds to owner?' do
      expect(membership).to respond_to(:owner?)
    end

    it 'correctly identifies member role' do
      expect(membership.member?).to be true
      expect(membership.admin?).to be false
      expect(membership.owner?).to be false
    end

    it 'correctly identifies admin role' do
      membership.update!(role: :admin)
      expect(membership.member?).to be false
      expect(membership.admin?).to be true
      expect(membership.owner?).to be false
    end

    it 'correctly identifies owner role' do
      membership.update!(role: :owner)
      expect(membership.member?).to be false
      expect(membership.admin?).to be false
      expect(membership.owner?).to be true
    end
  end
end
