class AttachmentSerializer < ActiveModel::Serializer
  attributes :id, :name, :link, :created_at, :updated_at, :file_url, :filename, :content_type, :size
  belongs_to :user, serializer: UserSerializer

  def file_url
    if object.file.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.file, only_path: true)
    else
      object.link
    end
  end

  def filename
    if object.file.attached?
      object.file.filename.to_s
    else
      object.name
    end
  end

  def content_type
    if object.file.attached?
      object.file.content_type
    else
      "text/html" # for links
    end
  end

  def size
    if object.file.attached?
      object.file.byte_size
    else
      0
    end
  end
end
