module Attachable
  extend ActiveSupport::Concern

  included do
    before_action :set_attachable
    before_action :ensure_member_access
  end

  def create
    attachment = @attachable.attachments.new(attachment_params)
    attachment.user = current_user

    if attachment.save
      render_success(attachment_json(attachment), :created)
    else
      render_error(attachment.errors.full_messages.join(", "))
    end
  end

  def destroy
    attachment = @attachable.attachments.find(params[:id])

    # Check if user can delete this attachment (owner or project member)
    project = @attachable.is_a?(Project) ? @attachable : @attachable.project
    unless attachment.user == current_user || member_of_project?(project)
      render_unauthorized("You do not have permission to delete this attachment")
      return
    end

    attachment.destroy
    render_success({ message: "Attachment removed successfully" })
  end

  private

  def attachment_params
    # Permit :file for uploads, :link for URLs, and a :name for the attachment.
    params.permit(:file, :link, :name)
  end

  def ensure_member_access
    project = @attachable.is_a?(Project) ? @attachable : @attachable.project
    unless member_of_project?(project)
      render_unauthorized("You do not have permission to manage attachments for this resource")
    end
  end

  def attachment_json(attachment)
    # Base JSON includes the attributes from our model
    base_json = attachment.as_json(only: [ :id, :name, :link, :created_at, :user_id ])

    # If a file is attached, add its URL and metadata to the JSON
    if attachment.file.attached?
      base_json[:file_url] = url_for(attachment.file)
      base_json[:file_name] = attachment.file.filename.to_s
      base_json[:content_type] = attachment.file.content_type
    end
    base_json
  end
end
