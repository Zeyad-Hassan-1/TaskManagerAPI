class Project < ApplicationRecord
  belongs_to :team
  has_many :tasks, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :users, through: :project_memberships
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings
  has_many :comments, as: :commentable
  has_many :attachments, as: :attachable

  validates :name, presence: true
  validates :description, presence: true
end
