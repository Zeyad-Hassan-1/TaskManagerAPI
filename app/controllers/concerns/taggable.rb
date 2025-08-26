module Taggable
  extend ActiveSupport::Concern

  included do
    before_action :set_taggable
    before_action :ensure_member_access
  end

  def create
    tag = Tag.find_or_create_by!(name: params[:name])
    @taggable.tags << tag unless @taggable.tags.include?(tag)
    render_success(@taggable.tags)
  end

  def destroy
    tag = @taggable.tags.find(params[:id])
    unless tag
      return render_error("Tag not found", :not_found)
    end

    @taggable.tags.destroy(tag)
    render_success({ message: "Tag removed successfully" })
  end
  private

  def ensure_member_access
    project = @taggable.is_a?(Project) ? @taggable : @taggable.project

    # For tasks, check both project membership and task membership
    if @taggable.is_a?(Task)
      task_membership = @taggable.task_memberships.find_by(user: current_user)
      has_access = member_of_project?(project) || task_membership.present?
    else
      has_access = member_of_project?(project)
    end

    unless has_access
      render_unauthorized("You do not have permission to manage tags for this resource")
    end
  end

  def tag_params
    params.permit(:name)
  end
end
