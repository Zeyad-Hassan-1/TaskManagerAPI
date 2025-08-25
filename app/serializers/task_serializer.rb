class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :priority, :due_date
end
