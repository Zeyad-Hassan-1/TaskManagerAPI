module Api
  module V1
    class TasksController < Api::ApplicationController
      before_action :set_task, only: [ :show, :update, :destroy ]

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
        @task = @project.tasks.build(task_params)

        if @task.save
          # Create task membership for the creator
          TaskMembership.create!(
            user: current_user,
            task: @task,
            role: :assignee
          )
          render_success(@task, :created)
        else
          render_error(@task.errors.full_messages.join(", "))
        end
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

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Task not found", :not_found)
      end

      def task_params
        # For now, tasks only have project_id which is set automatically
        # You can add more fields here as you expand the task model
        {}
      end
    end
  end
end
