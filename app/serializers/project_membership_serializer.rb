class ProjectMembershipSerializer < ActiveModel::Serializer
  attributes :id, :role, :created_at
  belongs_to :user, serializer: UserSerializer
end
