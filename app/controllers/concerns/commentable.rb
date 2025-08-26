module Commentable
extend ActiveSupport::Concern

  included do
    before_action :set_commentable
    before_action :ensure_member_access
  end

  def create
    comment = @commentable.comments.new(comment_params)
    comment.user = current_user
    if comment.save
      render_success(comment, :created)
    else
      render_error(comment.errors.full_messages.join(", "))
    end
  end

  def destroy
    comment = @commentable.comments.find(params[:id])
    unless comment
      return render_error("Comment not found", :not_found)
    end
    unless comment.user == current_user || owner_of_project?(@commentable.project)
      return render_unauthorized("You do not have permission to delete this comment")
    end

    @commentable.comments.destroy(comment)
    render_success({ message: "Comment removed successfully" })
  end

  def update
    comment = @commentable.comments.find(params[:id])
    unless comment
      return render_error("Comment not found", :not_found)
    end
    unless comment.user == current_user || owner_of_project?(@commentable.project)
      return render_unauthorized("You do not have permission to update this comment")
    end

    if comment.update(comment_params)
      render_success(comment)
    else
      render_error(comment.errors.full_messages.join(", "))
    end
  end

  private

  def ensure_member_access
    project = @commentable.is_a?(Project) ? @commentable : @commentable.project
    unless member_of_project?(project)
      render_unauthorized("You do not have permission to manage comments for this resource")
    end
  end

  def comment_params
    params.permit(:content)
  end
end
