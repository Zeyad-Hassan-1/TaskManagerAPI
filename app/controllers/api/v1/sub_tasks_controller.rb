module Api
  module V1
    class SubTasksController < Api::ApplicationController
      include Authorizable
      include Taskable

      before_action :set_parent_task, only: [ :index, :create ]

      # GET /api/v1/tasks/:task_id/sub_tasks
      def index
        @sub_tasks = @parent_task.sub_tasks
        render_success(@sub_tasks)
      end

      def show
        render_success(@task)
      end

      # POST /api/v1/tasks/:task_id/sub_tasks
      def create
        unless can_manage_tasks_in_project?(@parent_task.project)
          return render_forbidden("You must be an admin or owner of the project to create tasks")
        end

        ActiveRecord::Base.transaction do
          @task = @parent_task.sub_tasks.create!(task_params.merge(project_id: @parent_task.project_id))
          @task.task_memberships.create!(user: current_user, role: :assignee)
        end
        render_success(@task, :created)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      rescue ArgumentError => e
        # Handle enum validation errors (e.g., invalid priority)
        render_error("Priority is not included in the list")
      end

      private

      def set_parent_task
        @parent_task = current_user.tasks.find(params[:task_id])
      rescue ActiveRecord::RecordNotFound
        render_error("Parent task not found", :not_found)
      end

      def set_task
        # For nested routes, the parent is already set. For shallow routes, we find it.
        @task = Task.find(params[:id])
        @parent_task = @task.parent
        # Ensure the user has access through the project membership
        unless member_of_project?(@task.project)
          raise ActiveRecord::RecordNotFound
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Sub-task not found", :not_found)
      end
    end
  end
end
