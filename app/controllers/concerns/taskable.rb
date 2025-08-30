module Taskable
  extend ActiveSupport::Concern

  included do
    before_action :set_task, only: [ :show, :update, :destroy, :assign_member, :remove_member ]
    before_action :ensure_task_member_access, only: [ :show ]
    before_action :ensure_admin_access, only: [ :update, :assign_member, :remove_member ]
    before_action :ensure_owner_access, only: [ :destroy ]
  end

  def update
    if @task.update(task_params)
      serialized_task = TaskSerializer.new(@task).serializable_hash
      render json: { data: serialized_task }, status: :ok
    else
      render_error(@task.errors.full_messages.join(", "))
    end
  end

  def destroy
    @task.destroy
    render_success({ message: "Task deleted successfully" })
  end

  def assign_member
    user = User.find_by(username: params[:username])

    unless user
      return render_error("User not found", :not_found)
    end

    # Check if user is a member of the project
    user_project_membership = @task.project.project_memberships.find_by(user: user)
    unless user_project_membership
      return render_error("User must be a member of the project to be assigned to tasks")
    end

    # Only project owners and admins can assign members to tasks
    current_user_project_membership = @task.project.project_memberships.find_by(user: current_user)
    unless current_user_project_membership&.role.in?([ "owner", "admin" ])
      return render_error("Only project owners and admins can assign members to tasks")
    end

    if @task.task_memberships.exists?(user: user)
      return render_error("User is already a member of this task")
    end

    role = params[:role] || "assignee"
    unless [ "assignee", "reviewer", "watcher" ].include?(role)
      return render_error("Invalid role. Must be 'assignee', 'reviewer', or 'watcher'")
    end

    # Remove existing membership if user already has one
    @task.task_memberships.where(user: user).destroy_all

    @task.task_memberships.create!(
      user: user,
      role: role
    )

    # Create notification for task assignment if Notifiable concern is included
    if respond_to?(:create_notification)
      create_notification(user, @task, "assigned")
    end

    render_success({ message: "User assigned to task successfully" }, :created)
  end

  def remove_member
    user = User.find(params[:user_id])
    membership = @task.task_memberships.find_by(user: user)

    unless membership
      return render_error("User is not assigned to this task", :not_found)
    end

    # Get the user's project role to check permissions
    user_project_membership = @task.project.project_memberships.find_by(user: user)
    current_user_project_membership = @task.project.project_memberships.find_by(user: current_user)

    # Only project owners and admins can remove task members
    unless current_user_project_membership&.role.in?([ "owner", "admin" ])
      return render_error("Only project owners and admins can remove task members")
    end

    # Project owners cannot remove themselves from tasks
    if user == current_user && current_user_project_membership&.role == "owner"
      return render_error("Project owners cannot remove themselves from tasks")
    end

    # Only project owners can remove other owners or admins from tasks
    if user_project_membership&.role.in?([ "owner", "admin" ])
      unless current_user_project_membership&.role == "owner"
        return render_error("Only project owners can remove other owners or admins from tasks")
      end
    end

    # Allow users to remove themselves if they're not the project owner
    if user == current_user && current_user_project_membership&.role != "owner"
      membership.destroy
      return render_success({ message: "You removed yourself from the task successfully" })
    end

    # Don't allow removing the last assignee (task creator)
    if membership.role == "assignee" && @task.task_memberships.count == 1
      return render_error("Cannot remove the only assignee from a task")
    end

    membership.destroy
    render_success({ message: "User removed from task successfully" })
  end

  private

  def ensure_task_member_access
    unless @task.task_memberships.exists?(user: current_user)
      render_forbidden("You must be assigned to this task to view it")
    end
  end

  def ensure_member_access
    unless member_of_project?(@task.project)
      render_forbidden("You must be a member of this project to view tasks")
    end
  end

  def ensure_admin_access
    unless admin_of_project?(@task.project)
      render_forbidden("You must be an admin or owner of this project to perform this action")
    end
  end

  def ensure_owner_access
    unless owner_of_project?(@task.project)
      render_forbidden("You must be the owner of this project to delete tasks")
    end
  end

  def task_params
    params.require(:task).permit(:name, :description, :status, :priority, :due_date)
  end
end
