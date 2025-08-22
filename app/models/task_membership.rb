class TaskMembership < ApplicationRecord
  belongs_to :user
  belongs_to :task

  validates :user_id, presence: true
  validates :task_id, presence: true
  validates :role, presence: true

  # Define role enum
  enum :role, { assignee: 0, reviewer: 1, watcher: 2 }
end
