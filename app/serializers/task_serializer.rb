class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :priority, :due_date, :parent_id, :created_at, :updated_at

  # Associations
  belongs_to :project, serializer: ProjectSerializer
  has_many :users, serializer: UserSerializer
  has_many :sub_tasks, serializer: SubTaskSerializer
end
