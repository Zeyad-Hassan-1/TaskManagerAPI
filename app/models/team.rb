class Team < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :users, through: :team_memberships

  validates :name, presence: true
  validates :description, presence: true
end
