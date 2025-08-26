module Attachable
  extend ActiveSupport::Concern

  included do
    before_action :set_attachable
    before_action :ensure_member_access
  end

  def create
    # We need to decide if an attachment should belong to a user.
    # If so, we need a migration to add `user_id` to `attachments`.
    # For now, we'll proceed without it.
    attachment = @attachable.attachments.new(attachment_params)

    if attachment.save
      render_success(attachment_json(attachment), :created)
    else
      render_error(attachment.errors.full_messages.join(", "))
    end
  end

  def destroy
    attachment = @attachable.attachments.find(params[:id])

    # We'll need authorization here, probably based on project ownership
    # or who uploaded the file.

    attachment.destroy
    render_success({ message: "Attachment removed successfully" })
  end

  private

  def attachment_params
    # Permit :file for uploads, :link for URLs, and a :name for the attachment.
    params.permit(:file, :link)
  end

  def ensure_member_access
    project = @attachable.is_a?(Project) ? @attachable : @attachable.project
    unless member_of_project?(project)
      render_unauthorized("You do not have permission to manage attachments for this resource")
    end
  end

  def attachment_json(attachment)
    # Base JSON includes the attributes from our model
    base_json = attachment.as_json(only: [ :id, :link, :created_at ])

    # If a file is attached, add its URL and metadata to the JSON
    if attachment.file.attached?
      base_json[:file_url] = url_for(attachment.file)
      base_json[:file_name] = attachment.file.filename.to_s
      base_json[:content_type] = attachment.file.content_type
    end
    base_json
  end
end
