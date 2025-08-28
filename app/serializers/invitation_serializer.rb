class InvitationSerializer < ActiveModel::Serializer
  attributes :id, :role, :status, :created_at, :updated_at

  # Include inviter information
  belongs_to :inviter, serializer: UserSerializer

  # Include invitee information
  belongs_to :invitee, serializer: UserSerializer

  # Include the invitable (team or project) details
  attribute :invitable_type
  attribute :invitable_id
  attribute :invitable_name

  def invitable_name
    object.invitable.name
  end
end
