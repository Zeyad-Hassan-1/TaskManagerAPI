module Api
  module V1
    class TasksController < Api::ApplicationController
      include Taskable
      include Authorizable
      include Notifiable

      # GET /api/v1/projects/:project_id/tasks
      def index
        @project = Project.find(params[:project_id])

        # Check if user can access this project (either project member or team member)
        unless member_of_project?(@project) || member_of_team?(@project.team)
          return render_unauthorized("You must be a member of this project or its team to view tasks")
        end

        # Only show tasks where the user is assigned as a member
        user_task_ids = TaskMembership.where(user: current_user).pluck(:task_id)
        @tasks = @project.tasks.where(parent_id: nil, id: user_task_ids)

        serialized_tasks = @tasks.map do |task|
          TaskSerializer.new(task).serializable_hash
        end

        render json: { data: serialized_tasks }, status: :ok
      end

      # GET /api/v1/tasks/:id
      def show
        serialized_task = TaskSerializer.new(@task).serializable_hash
        render json: { data: serialized_task }, status: :ok
      end

      # POST /api/v1/projects/:project_id/tasks
      def create
        @project = Project.find(params[:project_id])

        # Only admins and owners can create tasks
        unless admin_of_project?(@project)
          return render_unauthorized("You must be an admin or owner of the project to create tasks")
        end

        ActiveRecord::Base.transaction do
          @task = @project.tasks.create!(task_params)
          @task.task_memberships.create!(user: current_user, role: :assignee)
        end

        serialized_task = TaskSerializer.new(@task).serializable_hash
        render json: { data: serialized_task }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      end

      private

      def set_task
        @task = Task.find(params[:id])

        # Check if user has access to this task via project/team membership
        unless member_of_project?(@task.project) || (@task.project.team && member_of_team?(@task.project.team))
          render_error("Task not found", :not_found)
          nil
        end
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      def task_params
        params.require(:task).permit(:name, :description, :status, :priority, :due_date)
      end
    end
  end
end
