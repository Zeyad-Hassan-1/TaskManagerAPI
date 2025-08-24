class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :bio, :admin, :email
end
