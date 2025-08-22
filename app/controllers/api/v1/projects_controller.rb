module Api
  module V1
    class ProjectsController < Api::ApplicationController
      before_action :set_project, only: [ :show, :update, :destroy ]

      # GET /api/v1/teams/:team_id/projects
      def index
        @team = current_user.teams.find(params[:team_id])
        @projects = @team.projects
        render_success(@projects)
      end

      # GET /api/v1/projects/:id
      def show
        render_success(@project)
      end

      # POST /api/v1/teams/:team_id/projects
      def create
        @team = current_user.teams.find(params[:team_id])
        @project = @team.projects.build(project_params)

        if @project.save
          # Create project membership for the creator
          ProjectMembership.create!(
            user: current_user,
            project: @project,
            role: :owner
          )
          render_success(@project, :created)
        else
          render_error(@project.errors.full_messages.join(", "))
        end
      end

      # PUT /api/v1/projects/:id
      def update
        if @project.update(project_params)
          render_success(@project)
        else
          render_error(@project.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/projects/:id
      def destroy
        @project.destroy
        render_success({ message: "Project deleted successfully" })
      end

      private

      def set_project
        @project = current_user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", :not_found)
      end

      def project_params
        params.require(:project).permit(:name, :discription)
      end
    end
  end
end
