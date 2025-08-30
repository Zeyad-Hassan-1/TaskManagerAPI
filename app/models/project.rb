class Project < ApplicationRecord
  belongs_to :team
  has_many :tasks, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :users, through: :project_memberships
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings
  has_many :comments, as: :commentable
  has_many :attachments, as: :attachable
  has_many :invitations, as: :invitable, dependent: :destroy

  enum :status, { active: 0, completed: 1, archived: 2 }

  validates :name, presence: true, uniqueness: { scope: :team_id, message: "must be unique within the team" }
  validates :description, presence: true
end
