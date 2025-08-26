class Api::V1::ProjectTagsController < Api::ApplicationController
  include Authorizable
  include Taggable

  private

  def set_taggable
    @taggable = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Project not found", :not_found)
  end
end
