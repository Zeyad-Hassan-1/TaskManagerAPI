class Api::V1::TaskCommentsController < ApplicationController
  include Authorizable
  include Commentable

  private

  def set_commentable
    @commentable = Task.find(params[:task_id])
  end
end
