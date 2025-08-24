class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :discription, :created_at, :updated_at

  has_many :users, serializer: UserSerializer
  has_many :team_memberships

  def team_memberships
    object.team_memberships.includes(:user).map do |membership|
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
