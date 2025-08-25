class Task < ApplicationRecord
  belongs_to :project
  has_many :task_memberships, dependent: :destroy
  has_many :users, through: :task_memberships

  enum :priority, { low: 0, medium: 1, high: 2 }

  validates :name, presence: true
  validates :project_id, presence: true
end
