require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'associations' do
    it 'belongs to attachable (polymorphic)' do
      association = Attachment.reflect_on_association(:attachable)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be_truthy
    end

    it 'belongs to user' do
      expect(Attachment.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has one attached file' do
      # Active Storage attachments are handled differently
      expect(Attachment.attachment_reflections.keys).to include('file')
    end
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    context 'with file attached' do
      it 'is valid when file is present' do
        attachment = build(:attachment, user: user, attachable: project, link: nil)
        # Simulate file attachment
        attachment.file.attach(
          io: StringIO.new("test content"),
          filename: "test.txt",
          content_type: "text/plain"
        )
        expect(attachment).to be_valid
      end
    end

    context 'with link provided' do
      it 'is valid when link is present and file is blank' do
        attachment = build(:attachment, user: user, attachable: project, link: "https://example.com/file.pdf")
        expect(attachment).to be_valid
      end
    end

    context 'validation requirements' do
      it 'requires either link or file' do
        attachment = build(:attachment, user: user, attachable: project, link: nil)
        expect(attachment).not_to be_valid
        expect(attachment.errors[:link]).to be_present
      end

      it 'requires user' do
        attachment = build(:attachment, user: nil, attachable: project)
        expect(attachment).not_to be_valid
        expect(attachment.errors[:user]).to include("must exist")
      end

      it 'requires attachable' do
        attachment = build(:attachment, user: user, attachable: nil)
        expect(attachment).not_to be_valid
        expect(attachment.errors[:attachable]).to include("must exist")
      end

      it 'is invalid with empty link and no file' do
        attachment = build(:attachment, user: user, attachable: project, link: "")
        expect(attachment).not_to be_valid
        expect(attachment.errors[:link]).to be_present
      end
    end
  end

  describe 'polymorphic associations' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:task) { create(:task) }

    it 'can belong to a project' do
      attachment = create(:attachment, user: user, attachable: project)
      expect(attachment.attachable).to eq(project)
      expect(attachment.attachable_type).to eq('Project')
    end

    it 'can belong to a task' do
      attachment = create(:attachment, user: user, attachable: task)
      expect(attachment.attachable).to eq(task)
      expect(attachment.attachable_type).to eq('Task')
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      attachment = create(:attachment)
      expect(attachment).to be_persisted
      expect(attachment.user).to be_present
      expect(attachment.attachable).to be_present
      # Factory should provide either link or file
      expect(attachment.link.present? || attachment.file.attached?).to be_truthy
    end
  end

  describe 'file handling' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    it 'can attach and access files' do
      attachment = build(:attachment, user: user, attachable: project, link: nil)
      attachment.file.attach(
        io: StringIO.new("test file content"),
        filename: "document.pdf",
        content_type: "application/pdf"
      )
      attachment.save!

      expect(attachment.file.attached?).to be_truthy
      expect(attachment.file.filename).to eq("document.pdf")
      expect(attachment.file.content_type).to eq("application/pdf")
    end
  end
end
