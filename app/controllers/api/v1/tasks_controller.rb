module Api
  module V1
    class TasksController < Api::ApplicationController
      include Authorizable
      include Taskable

      # GET /api/v1/projects/:project_id/tasks
      def index
        @project = current_user.projects.find(params[:project_id])
        @tasks = @project.tasks.where(parent_id: nil)
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

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end
    end
  end
end
