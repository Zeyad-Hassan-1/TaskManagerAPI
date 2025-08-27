require 'rails_helper'

RSpec.describe Activity, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:actor) }
    it { should belong_to(:notifiable) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:activity)).to be_valid
    end

    it 'has a valid read activity factory' do
      expect(build(:activity, :read)).to be_valid
    end
  end

  describe 'attributes' do
    it 'has action attribute' do
      activity = build(:activity, action: 'invited')
      expect(activity.action).to eq('invited')
    end

    it 'has read_at attribute' do
      activity = build(:activity, read_at: nil)
      expect(activity.read_at).to be_nil
    end
  end

  describe 'polymorphic associations' do
    context 'with user actor' do
      let(:actor_user) { create(:user) }
      let(:activity) { create(:activity, actor: actor_user, notifiable: team) }

      it 'belongs to a user as actor' do
        expect(activity.actor).to eq(actor_user)
        expect(activity.actor_type).to eq('User')
      end
    end

    context 'with team notifiable' do
      let(:actor_user) { create(:user) }
      let(:activity) { create(:activity, actor: actor_user, notifiable: team) }

      it 'belongs to a team as notifiable' do
        expect(activity.notifiable).to eq(team)
        expect(activity.notifiable_type).to eq('Team')
      end
    end
  end
end
