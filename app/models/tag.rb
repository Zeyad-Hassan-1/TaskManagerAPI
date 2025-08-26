class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :tasks, through: :taggings, source: :taggable, source_type: "Task"
  has_many :projects, through: :taggings, source: :taggable, source_type: "Project"

  validates :name, presence: true, uniqueness: true
end
