class Project < ApplicationRecord
  belongs_to :team
  has_many :tasks, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :users, through: :project_memberships

  validates :name, presence: true
  validates :description, presence: true
end
