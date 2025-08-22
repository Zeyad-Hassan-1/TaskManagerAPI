class Task < ApplicationRecord
  belongs_to :project
  has_many :task_memberships, dependent: :destroy
  has_many :users, through: :task_memberships

  validates :project_id, presence: true
end
