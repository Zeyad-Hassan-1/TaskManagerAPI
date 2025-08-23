require 'rails_helper'

# Create a test controller class to test the concern
class TestController < Api::ApplicationController
  include Authorizable

  def current_user
    @current_user
  end

  def set_current_user(user)
    @current_user = user
  end
end

RSpec.describe Authorizable, type: :controller do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:project) { create(:project, team: team) }
  let(:task) { create(:task, project: project) }
  let(:controller) { TestController.new }

  before do
    controller.set_current_user(user)
  end

  describe 'team permissions' do
    context 'when user is a member' do
      before do
        create(:team_membership, user: user, team: team, role: :member)
      end

      it 'returns true for member_of_team?' do
        expect(controller.send(:member_of_team?, team)).to be true
      end

      it 'returns false for admin_of_team?' do
        expect(controller.send(:admin_of_team?, team)).to be false
      end

      it 'returns false for owner_of_team?' do
        expect(controller.send(:owner_of_team?, team)).to be false
      end
    end

    context 'when user is an admin' do
      before do
        create(:team_membership, user: user, team: team, role: :admin)
      end

      it 'returns true for member_of_team?' do
        expect(controller.send(:member_of_team?, team)).to be true
      end

      it 'returns true for admin_of_team?' do
        expect(controller.send(:admin_of_team?, team)).to be true
      end

      it 'returns false for owner_of_team?' do
        expect(controller.send(:owner_of_team?, team)).to be false
      end
    end

    context 'when user is an owner' do
      before do
        create(:team_membership, user: user, team: team, role: :owner)
      end

      it 'returns true for member_of_team?' do
        expect(controller.send(:member_of_team?, team)).to be true
      end

      it 'returns true for admin_of_team?' do
        expect(controller.send(:admin_of_team?, team)).to be true
      end

      it 'returns true for owner_of_team?' do
        expect(controller.send(:owner_of_team?, team)).to be true
      end
    end

    context 'when user is not a member' do
      it 'returns false for all permission checks' do
        expect(controller.send(:member_of_team?, team)).to be false
        expect(controller.send(:admin_of_team?, team)).to be false
        expect(controller.send(:owner_of_team?, team)).to be false
      end
    end
  end

  describe 'project permissions' do
    context 'when user is a member' do
      before do
        create(:project_membership, user: user, project: project, role: :member)
      end

      it 'returns true for member_of_project?' do
        expect(controller.send(:member_of_project?, project)).to be true
      end

      it 'returns false for admin_of_project?' do
        expect(controller.send(:admin_of_project?, project)).to be false
      end

      it 'returns false for owner_of_project?' do
        expect(controller.send(:owner_of_project?, project)).to be false
      end
    end

    context 'when user is an admin' do
      before do
        create(:project_membership, user: user, project: project, role: :admin)
      end

      it 'returns true for member_of_project?' do
        expect(controller.send(:member_of_project?, project)).to be true
      end

      it 'returns true for admin_of_project?' do
        expect(controller.send(:admin_of_project?, project)).to be true
      end

      it 'returns false for owner_of_project?' do
        expect(controller.send(:owner_of_project?, project)).to be false
      end
    end

    context 'when user is an owner' do
      before do
        create(:project_membership, user: user, project: project, role: :owner)
      end

      it 'returns true for member_of_project?' do
        expect(controller.send(:member_of_project?, project)).to be true
      end

      it 'returns true for admin_of_project?' do
        expect(controller.send(:admin_of_project?, project)).to be true
      end

      it 'returns true for owner_of_project?' do
        expect(controller.send(:owner_of_project?, project)).to be true
      end
    end
  end

  describe 'permission methods' do
    before do
      create(:team_membership, user: user, team: team, role: :admin)
      create(:project_membership, user: user, project: project, role: :admin)
    end

    it 'can_invite_to_team? returns true for admin' do
      expect(controller.send(:can_invite_to_team?, team)).to be true
    end

    it 'can_invite_to_project? returns true for admin' do
      expect(controller.send(:can_invite_to_project?, project)).to be true
    end

    it 'can_manage_tasks_in_project? returns true for admin' do
      expect(controller.send(:can_manage_tasks_in_project?, project)).to be true
    end

    it 'can_assign_tasks? returns true for admin' do
      expect(controller.send(:can_assign_tasks?, project)).to be true
    end
  end

  describe 'owner permissions' do
    before do
      create(:team_membership, user: user, team: team, role: :owner)
      create(:project_membership, user: user, project: project, role: :owner)
    end

    it 'can_manage_team_members? returns true for owner' do
      expect(controller.send(:can_manage_team_members?, team)).to be true
    end

    it 'can_manage_project_members? returns true for owner' do
      expect(controller.send(:can_manage_project_members?, project)).to be true
    end

    it 'can_delete_team? returns true for owner' do
      expect(controller.send(:can_delete_team?, team)).to be true
    end

    it 'can_delete_project? returns true for owner' do
      expect(controller.send(:can_delete_project?, project)).to be true
    end

    it 'can_delete_task? returns true for owner' do
      expect(controller.send(:can_delete_task?, task)).to be true
    end
  end
end
