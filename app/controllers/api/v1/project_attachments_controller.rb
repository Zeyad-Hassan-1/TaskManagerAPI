class Api::V1::ProjectAttachmentsController < Api::ApplicationController
  include Authorizable
  include Attachable

  private

  def set_attachable
    @attachable = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Project not found", :not_found)
  end
end
