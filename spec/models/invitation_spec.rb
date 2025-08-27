require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project) }

  describe 'associations' do
    it { should belong_to(:inviter).class_name('User') }
    it { should belong_to(:invitee).class_name('User') }
    it { should belong_to(:invitable) }
  end

  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending accepted declined]) }
  end

  describe '#pending?' do
    it 'returns true when status is pending' do
      invitation = build(:invitation, status: 'pending')
      expect(invitation.pending?).to be true
    end

    it 'returns false when status is not pending' do
      invitation = build(:invitation, status: 'accepted')
      expect(invitation.pending?).to be false
    end
  end

  describe '#accepted?' do
    it 'returns true when status is accepted' do
      invitation = build(:invitation, status: 'accepted')
      expect(invitation.accepted?).to be true
    end

    it 'returns false when status is not accepted' do
      invitation = build(:invitation, status: 'pending')
      expect(invitation.accepted?).to be false
    end
  end

  describe '#declined?' do
    it 'returns true when status is declined' do
      invitation = build(:invitation, status: 'declined')
      expect(invitation.declined?).to be true
    end

    it 'returns false when status is not declined' do
      invitation = build(:invitation, status: 'pending')
      expect(invitation.declined?).to be false
    end
  end

  describe 'polymorphic associations' do
    context 'with team invitable' do
      let(:invitation) { create(:invitation, :for_team, invitable: team) }

      it 'belongs to a team' do
        expect(invitation.invitable).to eq(team)
        expect(invitation.invitable_type).to eq('Team')
      end
    end

    context 'with project invitable' do
      let(:invitation) { create(:invitation, :for_project, invitable: project) }

      it 'belongs to a project' do
        expect(invitation.invitable).to eq(project)
        expect(invitation.invitable_type).to eq('Project')
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:invitation)).to be_valid
    end

    it 'has a valid team invitation factory' do
      expect(build(:invitation, :for_team)).to be_valid
    end

    it 'has a valid project invitation factory' do
      expect(build(:invitation, :for_project)).to be_valid
    end

    it 'has a valid accepted invitation factory' do
      expect(build(:invitation, :accepted)).to be_valid
    end

    it 'has a valid declined invitation factory' do
      expect(build(:invitation, :declined)).to be_valid
    end
  end
end
