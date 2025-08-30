class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status, :created_at, :updated_at, :members_count, :tasks_count, :sub_tasks_count

  # Include team information
  belongs_to :team, serializer: TeamSerializer

  # Include project members with their roles
  has_many :project_memberships, serializer: ProjectMembershipSerializer
  has_many :comments, serializer: CommentSerializer
  has_many :tags, serializer: TagSerializer

  def members_count
    object.users.count
  end

  def tasks_count
    object.tasks.where(parent_id: nil).count  # Only root tasks, not sub-tasks
  end

  def sub_tasks_count
    object.tasks.where.not(parent_id: nil).count  # Only sub-tasks
  end
end
