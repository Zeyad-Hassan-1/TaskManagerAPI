class TeamMembership < ApplicationRecord
  belongs_to :user
  belongs_to :team

  validates :user_id, presence: true
  validates :team_id, presence: true
  validates :role, presence: true

  # Define role enum
  enum :role, { member: 0, admin: 1, owner: 2 }
end
