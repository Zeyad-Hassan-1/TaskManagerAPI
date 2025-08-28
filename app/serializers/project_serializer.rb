class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :created_at, :updated_at

  # Include team information
  belongs_to :team, serializer: TeamSerializer

  # Include project members with their roles
  has_many :project_memberships
  has_many :comments
  has_many :tags

  def project_memberships
    object.project_memberships.includes(:user).map do |membership|
      {
        id: membership.id,
        user_id: membership.user_id,
        username: membership.user.username,
        email: membership.user.email,
        role: membership.role,
        created_at: membership.created_at
      }
    end
  end
end
