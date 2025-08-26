class Api::V1::ProjectCommentsController < Api::ApplicationController
  include Authorizable
  include Commentable

  private

  def set_commentable
    @commentable = Project.find(params[:project_id])
  end
end
