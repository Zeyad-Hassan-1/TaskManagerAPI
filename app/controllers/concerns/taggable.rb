module Taggable
  extend ActiveSupport::Concern

  included do
    before_action :set_taggable
    before_action :ensure_project_member
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
  def tag_params
    params.permit(:name)
  end
end
