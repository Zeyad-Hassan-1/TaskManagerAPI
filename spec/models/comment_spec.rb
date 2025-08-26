require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'associations' do
    it 'belongs to commentable (polymorphic)' do
      expect(Comment.reflect_on_association(:commentable).macro).to eq(:belongs_to)
      expect(Comment.reflect_on_association(:commentable).options[:polymorphic]).to be_truthy
    end

    it 'belongs to user' do
      expect(Comment.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    it 'is valid with valid attributes' do
      comment = build(:comment, user: user, commentable: project)
      expect(comment).to be_valid
    end

    it 'requires content' do
      comment = build(:comment, user: user, commentable: project, content: nil)
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("can't be blank")
    end

    it 'requires content to be present (not empty string)' do
      comment = build(:comment, user: user, commentable: project, content: "")
      expect(comment).not_to be_valid
      expect(comment.errors[:content]).to include("can't be blank")
    end

    it 'requires user' do
      comment = build(:comment, user: nil, commentable: project)
      expect(comment).not_to be_valid
      expect(comment.errors[:user]).to include("must exist")
    end

    it 'requires commentable' do
      comment = build(:comment, user: user, commentable: nil)
      expect(comment).not_to be_valid
      expect(comment.errors[:commentable]).to include("must exist")
    end
  end

  describe 'polymorphic associations' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:task) { create(:task) }

    it 'can belong to a project' do
      comment = create(:comment, user: user, commentable: project)
      expect(comment.commentable).to eq(project)
      expect(comment.commentable_type).to eq('Project')
    end

    it 'can belong to a task' do
      comment = create(:comment, user: user, commentable: task)
      expect(comment.commentable).to eq(task)
      expect(comment.commentable_type).to eq('Task')
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      comment = create(:comment)
      expect(comment).to be_persisted
      expect(comment.content).to be_present
      expect(comment.user).to be_present
      expect(comment.commentable).to be_present
    end
  end
end
