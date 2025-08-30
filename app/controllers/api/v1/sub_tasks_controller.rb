module Api
  module V1
    class SubTasksController < Api::ApplicationController
      include Taskable
      include Authorizable
      include Notifiable

      before_action :set_parent_task, only: [ :index, :create ]

      # GET /api/v1/tasks/:task_id/sub_tasks
      def index
        # Check if user has access to the parent task
        unless member_of_project?(@parent_task.project) || (@parent_task.project.team && member_of_team?(@parent_task.project.team))
          return render_error("Task not found", :not_found)
        end

        @sub_tasks = @parent_task.sub_tasks

        serialized_sub_tasks = @sub_tasks.map do |sub_task|
          TaskSerializer.new(sub_task).serializable_hash
        end

        render json: { data: serialized_sub_tasks }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      # Dummy show method to satisfy Taskable concern callback requirements
      def show
        serialized_task = TaskSerializer.new(@task).serializable_hash
        render json: { data: serialized_task }, status: :ok
      end

      # POST /api/v1/tasks/:task_id/sub_tasks
      def create
        # Only admins and owners can create sub-tasks
        unless admin_of_project?(@parent_task.project)
          return render_unauthorized("You must be an admin or owner of the project to create sub-tasks")
        end

        @task = @parent_task.sub_tasks.build(task_params)
        @task.project = @parent_task.project

        if @task.save
          # Assign the current user as the creator/assignee
          @task.task_memberships.create!(user: current_user, role: :assignee)

          serialized_task = TaskSerializer.new(@task).serializable_hash
          render json: { data: serialized_task }, status: :created
        else
          render_error(@task.errors.full_messages.join(", "))
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      private

      def set_parent_task
        @parent_task = Task.find(params[:task_id])

        # Check if user has access to the parent task
        unless member_of_project?(@parent_task.project) || (@parent_task.project.team && member_of_team?(@parent_task.project.team))
          render_error("Task not found", :not_found)
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      def set_task
        @task = Task.find(params[:id])

        # Check if user has access to this sub-task via project/team membership
        unless member_of_project?(@task.project) || (@task.project.team && member_of_team?(@task.project.team))
          render_error("Sub-task not found", :not_found)
          nil
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Sub-task not found", :not_found)
      end

      def task_params
        params.require(:task).permit(:name, :description, :status, :priority, :due_date)
      end
    end
  end
end
