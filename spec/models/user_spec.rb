require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'requires a username' do
      user = build(:user, username: nil)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it 'requires a unique username' do
      existing_user = create(:user)
      user = build(:user, username: existing_user.username)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("has already been taken")
    end

    it 'requires a password' do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'accepts valid email when provided' do
      user = build(:user, email: 'test@example.com')
      expect(user).to be_valid
    end

    it 'requires email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'has many team_memberships' do
      expect(User.reflect_on_association(:team_memberships).macro).to eq(:has_many)
    end

    it 'has many teams through team_memberships' do
      association = User.reflect_on_association(:teams)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:team_memberships)
    end

    it 'has many project_memberships' do
      expect(User.reflect_on_association(:project_memberships).macro).to eq(:has_many)
    end

    it 'has many projects through project_memberships' do
      association = User.reflect_on_association(:projects)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:project_memberships)
    end

    it 'has many task_memberships' do
      expect(User.reflect_on_association(:task_memberships).macro).to eq(:has_many)
    end

    it 'has many tasks through task_memberships' do
      association = User.reflect_on_association(:tasks)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:task_memberships)
    end

    it 'has many refresh_tokens' do
      expect(User.reflect_on_association(:refresh_tokens).macro).to eq(:has_many)
    end
  end

  describe 'methods' do
    let(:user) { create(:user) }

    describe '#admin?' do
      it 'returns false by default' do
        expect(user.admin?).to be false
      end

      it 'returns true when admin is true' do
        user.update(admin: true)
        expect(user.admin?).to be true
      end
    end

    describe '#generate_refresh_token' do
      it 'creates a refresh token' do
        expect { user.generate_refresh_token }.to change(user.refresh_tokens, :count).by(1)
      end

      it 'returns a raw token' do
        token = user.generate_refresh_token
        expect(token).to be_a(String)
        expect(token.length).to eq(128) # 64 bytes in hex = 128 characters
      end
    end

    describe '#revoke_all_refresh_tokens!' do
      before do
        user.generate_refresh_token
        user.generate_refresh_token
      end

      it 'revokes all tokens' do
        expect { user.revoke_all_refresh_tokens! }.to change {
          user.refresh_tokens.where(revoked_at: nil).count
        }.from(2).to(0)
      end
    end

    describe '#generate_password_reset_token!' do
      it 'generates a reset token' do
        user.generate_password_reset_token!
        expect(user.reset_token).to be_present
        expect(user.reset_sent_at).to be_present
      end
    end

    describe '#password_reset_expired?' do
      it 'returns false for recent token' do
        user.generate_password_reset_token!
        expect(user.password_reset_expired?).to be false
      end

      it 'returns true for old token' do
        user.update(reset_sent_at: 2.hours.ago)
        expect(user.password_reset_expired?).to be true
      end
    end
  end

  describe 'secure password' do
    it 'encrypts the password' do
      user = create(:user, password: 'secret123')
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('secret123')
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'secret123')
      expect(user.authenticate('secret123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user = create(:user, password: 'secret123')
      expect(user.authenticate('wrong_password')).to be false
    end
  end

  describe 'dependent destroy' do
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    it 'destroys associated team_memberships when user is destroyed' do
      create(:team_membership, user: user, team: team, role: :owner)

      expect { user.destroy }.to change(TeamMembership, :count).by(-1)
    end

    it 'destroys associated project_memberships when user is destroyed' do
      create(:project, team: team, owner: user)
      # The factory creates one project membership for the owner

      expect { user.destroy }.to change(ProjectMembership, :count).by(-1)
    end

    it 'destroys associated task_memberships when user is destroyed' do
      project = create(:project, team: team)  # Don't set owner to avoid extra membership
      task = create(:task, project: project)
      create(:task_membership, user: user, task: task, role: :assignee)

      expect { user.destroy }.to change(TaskMembership, :count).by(-1)
    end
  end
end
