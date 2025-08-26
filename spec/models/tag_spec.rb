require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it 'has many taggings' do
      association = Tag.reflect_on_association(:taggings)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it 'has many tasks through taggings' do
      association = Tag.reflect_on_association(:tasks)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:taggings)
      expect(association.options[:source]).to eq(:taggable)
      expect(association.options[:source_type]).to eq("Task")
    end

    it 'has many projects through taggings' do
      association = Tag.reflect_on_association(:projects)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:taggings)
      expect(association.options[:source]).to eq(:taggable)
      expect(association.options[:source_type]).to eq("Project")
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      tag = build(:tag)
      expect(tag).to be_valid
    end

    it 'requires name' do
      tag = build(:tag, name: nil)
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    it 'requires name to be present (not empty string)' do
      tag = build(:tag, name: "")
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("can't be blank")
    end

    it 'requires unique name' do
      existing_tag = create(:tag)
      tag = build(:tag, name: existing_tag.name)
      expect(tag).not_to be_valid
      expect(tag.errors[:name]).to include("has already been taken")
    end

    it 'allows case-sensitive duplicates' do
      create(:tag, name: 'urgent')
      tag = build(:tag, name: 'URGENT')
      expect(tag).to be_valid
    end
  end

  describe 'associations behavior' do
    let(:tag) { create(:tag) }
    let(:project) { create(:project) }
    let(:task) { create(:task) }

    it 'can be associated with projects' do
      create(:tagging, tag: tag, taggable: project)
      expect(tag.projects).to include(project)
    end

    it 'can be associated with tasks' do
      create(:tagging, tag: tag, taggable: task)
      expect(tag.tasks).to include(task)
    end

    it 'destroys associated taggings when destroyed' do
      create(:tagging, tag: tag, taggable: project)
      expect { tag.destroy }.to change(Tagging, :count).by(-1)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      tag = create(:tag)
      expect(tag).to be_persisted
      expect(tag.name).to be_present
    end

    it 'creates tags with unique names' do
      tag1 = create(:tag)
      tag2 = create(:tag)
      expect(tag1.name).not_to eq(tag2.name)
    end
  end
end
