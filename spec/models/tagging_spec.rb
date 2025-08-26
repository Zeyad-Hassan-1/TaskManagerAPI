require 'rails_helper'

RSpec.describe Tagging, type: :model do
  describe 'associations' do
    it 'belongs to tag' do
      expect(Tagging.reflect_on_association(:tag).macro).to eq(:belongs_to)
    end

    it 'belongs to taggable (polymorphic)' do
      association = Tagging.reflect_on_association(:taggable)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be_truthy
    end
  end

  describe 'validations' do
    let(:tag) { create(:tag) }
    let(:project) { create(:project) }

    it 'is valid with valid attributes' do
      tagging = build(:tagging, tag: tag, taggable: project)
      expect(tagging).to be_valid
    end

    it 'requires tag' do
      tagging = build(:tagging, tag: nil, taggable: project)
      expect(tagging).not_to be_valid
      expect(tagging.errors[:tag]).to include("must exist")
    end

    it 'requires taggable' do
      tagging = build(:tagging, tag: tag, taggable: nil)
      expect(tagging).not_to be_valid
      expect(tagging.errors[:taggable]).to include("must exist")
    end
  end

  describe 'polymorphic associations' do
    let(:tag) { create(:tag) }
    let(:project) { create(:project) }
    let(:task) { create(:task) }

    it 'can tag a project' do
      tagging = create(:tagging, tag: tag, taggable: project)
      expect(tagging.taggable).to eq(project)
      expect(tagging.taggable_type).to eq('Project')
    end

    it 'can tag a task' do
      tagging = create(:tagging, tag: tag, taggable: task)
      expect(tagging.taggable).to eq(task)
      expect(tagging.taggable_type).to eq('Task')
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      tagging = create(:tagging)
      expect(tagging).to be_persisted
      expect(tagging.tag).to be_present
      expect(tagging.taggable).to be_present
    end
  end

  describe 'through associations' do
    let(:tag) { create(:tag) }
    let(:project) { create(:project) }
    let(:task) { create(:task) }

    it 'enables tag to access projects through taggings' do
      create(:tagging, tag: tag, taggable: project)
      expect(tag.projects.reload).to include(project)
    end

    it 'enables tag to access tasks through taggings' do
      create(:tagging, tag: tag, taggable: task)
      expect(tag.tasks.reload).to include(task)
    end
  end
end
