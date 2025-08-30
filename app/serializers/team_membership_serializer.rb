class TeamMembershipSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :role, :created_at

  belongs_to :user

  def user
    {
      id: object.user.id,
      username: object.user.username,
      email: object.user.email
    }
  end
end
