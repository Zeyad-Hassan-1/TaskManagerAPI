class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :bio, :admin, :email, :created_at, :updated_at
end
