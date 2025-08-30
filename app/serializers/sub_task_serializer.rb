class SubTaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status, :priority, :due_date, :parent_id, :created_at, :updated_at
  has_many :comments
  has_many :tags
end
