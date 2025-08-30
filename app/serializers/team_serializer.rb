class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :created_at, :updated_at, :members_count, :projects_count

  has_many :team_memberships, serializer: TeamMembershipSerializer

  def members_count
    object.users.count
  end

  def projects_count
    object.projects.count
  end
end
