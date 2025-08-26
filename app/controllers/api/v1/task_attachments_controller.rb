class Api::V1::TaskAttachmentsController < Api::ApplicationController
  include Authorizable
  include Attachable

  private

  def set_attachable
    @attachable = Task.find(params[:task_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Task not found", :not_found)
  end
end
