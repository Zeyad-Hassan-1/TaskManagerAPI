class Team < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships
  has_many :invitations, as: :invitable, dependent: :destroy

  validates :name, presence: true, uniqueness: { message: "Team name must be unique" }
  validates :description, presence: true
end
