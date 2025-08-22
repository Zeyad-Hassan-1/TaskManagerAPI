class ProjectMembership < ApplicationRecord
  belongs_to :user
  belongs_to :project

  validates :user_id, presence: true
  validates :project_id, presence: true
  validates :role, presence: true

  # Define role enum
  enum :role, { member: 0, admin: 1, owner: 2 }
end
