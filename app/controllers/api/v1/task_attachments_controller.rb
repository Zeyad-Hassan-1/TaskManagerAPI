class Api::V1::TaskAttachmentsController < Api::ApplicationController
  include Authorizable
  include Attachable

  # GET /api/v1/tasks/:task_id/attachments/:id/download
  def download
    attachment = @attachable.attachments.find(params[:id])

    if attachment.file.attached?
      redirect_to rails_blob_url(attachment.file, disposition: "attachment")
    else
      render_error("File not found", :not_found)
    end
  end

  private

  def set_attachable
    @attachable = Task.find(params[:task_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Task not found", :not_found)
  end
end
