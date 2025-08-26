class Task < ApplicationRecord
  belongs_to :project
  has_many :task_memberships, dependent: :destroy
  has_many :users, through: :task_memberships
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings
  has_many :comments, as: :commentable
  has_many :attachments, as: :attachable

  # Self Join
  belongs_to :parent, class_name: "Task", optional: true
  has_many :sub_tasks, class_name: "Task", foreign_key: "parent_id", dependent: :destroy

  enum :priority, { low: 0, medium: 1, high: 2 }

  validates :name, presence: true
  validates :project_id, presence: true
end
