class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :bio, :admin, :email, :created_at, :updated_at, :profile_picture

  def profile_picture
    object.profile_picture_url
  end
end
