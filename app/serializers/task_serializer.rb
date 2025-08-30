class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :status, :priority, :due_date, :parent_id, :created_at, :updated_at,
             :sub_tasks_count, :comments_count, :tags_count, :members_count, :attachments_count

  # Associations
  belongs_to :project, serializer: ProjectSerializer
  has_many :users, serializer: UserSerializer
  has_many :sub_tasks, serializer: SubTaskSerializer
  has_many :comments, serializer: CommentSerializer
  has_many :tags, serializer: TagSerializer
  has_many :attachments, serializer: AttachmentSerializer

  def sub_tasks_count
    object.sub_tasks.count
  end

  def comments_count
    object.comments.count
  end

  def tags_count
    object.tags.count
  end

  def members_count
    object.users.count
  end

  def attachments_count
    object.attachments.count
  end
end
