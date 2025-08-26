class Api::V1::TaskTagsController < ApplicationController
  include Authorizable
  include Taggable

  private

  def set_taggable
    @taggable = Task.find(params[:task_id])
  rescue ActiveRecord::RecordNotFound
    render_error("Task not found", :not_found)
  end
end
