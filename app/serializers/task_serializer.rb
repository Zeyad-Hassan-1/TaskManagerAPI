class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :priority, :due_date, :parent_id
  has_many :sub_tasks
end
