module Api
  module V1
    class TasksController < Api::ApplicationController
      include Authorizable

      before_action :set_task, only: [ :show, :update, :destroy, :assign_member, :remove_member ]
      before_action :ensure_member_access, only: [ :show ]
      before_action :ensure_admin_access, only: [ :update, :assign_member, :remove_member ]
      before_action :ensure_owner_access, only: [ :destroy ]

      # GET /api/v1/projects/:project_id/tasks
      def index
        @project = current_user.projects.find(params[:project_id])
        @tasks = @project.tasks
        render_success(@tasks)
      end

      # GET /api/v1/tasks/:id
      def show
        render_success(@task)
      end

      # POST /api/v1/projects/:project_id/tasks
      def create
        @project = current_user.projects.find(params[:project_id])

        # Only admins and owners can create tasks
        unless can_manage_tasks_in_project?(@project)
          return render_unauthorized("You must be an admin or owner of the project to create tasks")
        end

        ActiveRecord::Base.transaction do
          @task = @project.tasks.create!(task_params)
          @task.task_memberships.create!(user: current_user, role: :assignee)
        end
        render_success(@task, :created)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      end

      # PUT /api/v1/tasks/:id
      def update
        if @task.update(task_params)
          render_success(@task)
        else
          render_error(@task.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy
        render_success({ message: "Task deleted successfully" })
      end

      # POST /api/v1/tasks/:id/assign
      def assign_member
        user = User.find_by(username: params[:username])

        unless user
          return render_error("User not found", :not_found)
        end

        # Check if user is a member of the project
        unless member_of_project?(@task.project)
          return render_error("User must be a member of the project to be assigned to tasks")
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

        render_success({ message: "User assigned to task successfully" }, :created)
      end

      # DELETE /api/v1/tasks/:id/members/:user_id
      def remove_member
        user = User.find(params[:user_id])
        membership = @task.task_memberships.find_by(user: user)

        unless membership
          return render_error("User is not assigned to this task", :not_found)
        end

        membership.destroy
        render_success({ message: "User removed from task successfully" })
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      def ensure_member_access
        unless member_of_project?(@task.project)
          render_unauthorized("You must be a member of this project to view tasks")
        end
      end

      def ensure_admin_access
        unless admin_of_project?(@task.project)
          render_unauthorized("You must be an admin or owner of this project to perform this action")
        end
      end

      def ensure_owner_access
        unless owner_of_project?(@task.project)
          render_unauthorized("You must be the owner of this project to delete tasks")
        end
      end

      def task_params
        # For now, tasks only have project_id which is set automatically
        # You can add more fields here as you expand the task model
        {}
      end
    end
  end
end
