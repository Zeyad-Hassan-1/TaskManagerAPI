module Api
  module V1
    class ProjectsController < Api::ApplicationController
      include Authorizable
      include Notifiable

      before_action :set_project, only: [ :show, :update, :destroy, :invite_member, :remove_member, :promote_member, :demote_member ]
      before_action :ensure_member_access, only: [ :show ]
      before_action :ensure_admin_access, only: [ :update, :invite_member ]
      before_action :ensure_owner_access, only: [ :destroy, :remove_member, :promote_member, :demote_member ]

      # GET /api/v1/teams/:team_id/projects
      def index
        @team = current_user.teams.find(params[:team_id])
        @projects = @team.projects

        serialized_projects = @projects.map do |project|
          ProjectSerializer.new(project).serializable_hash
        end

        render json: { data: serialized_projects }, status: :ok
      end

      # GET /api/v1/projects/:id
      def show
        serialized_project = ProjectSerializer.new(@project).serializable_hash
        render json: { data: serialized_project }, status: :ok
      end

      # POST /api/v1/teams/:team_id/projects
      def create
        @team = current_user.teams.find(params[:team_id])

        # Only admins and owners can create projects
        unless admin_of_team?(@team)
          return render_unauthorized("You must be an admin or owner of the team to create projects")
        end

        ActiveRecord::Base.transaction do
          @project = @team.projects.create!(project_params)
          @project.project_memberships.create!(user: current_user, role: :owner)
        end

        serialized_project = ProjectSerializer.new(@project).serializable_hash
        render json: { data: serialized_project }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      end

      # PUT /api/v1/projects/:id
      def update
        if @project.update(project_params)
          serialized_project = ProjectSerializer.new(@project).serializable_hash
          render json: { data: serialized_project }, status: :ok
        else
          render_error(@project.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/projects/:id
      def destroy
        @project.destroy
        render_success({ message: "Project deleted successfully" })
      end

      # POST /api/v1/projects/:id/invite
      def invite_member
        invitee = User.find_by(username: params[:username])
        role = params[:role] || "member"

        unless invitee
          return render_error("User not found", :not_found)
        end

        if @project.project_memberships.exists?(user: invitee)
          return render_error("User is already a member of this project")
        end

        invitation = Invitation.new(
          inviter: current_user,
          invitee: invitee,
          invitable: @project,
          role: role,
          status: "pending"
        )

        if invitation.save
          create_notification(invitee, invitation, "invited")
          render_success({ message: "Invitation sent successfully." }, :created)
        else
          render_error(invitation.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/projects/:id/members/:user_id
      def remove_member
        user = User.find(params[:user_id])
        membership = @project.project_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this project", :not_found)
        end

        if membership.owner?
          return render_error("Cannot remove project owner")
        end

        membership.destroy
        render_success({ message: "Member removed successfully" })
      end

      # PUT /api/v1/projects/:id/members/:user_id/promote
      def promote_member
        user = User.find(params[:user_id])
        membership = @project.project_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this project", :not_found)
        end

        if membership.owner?
          return render_error("User is already the owner")
        end

        if membership.admin?
          return render_error("User is already an admin")
        end

        membership.update!(role: :admin)
        render_success({ message: "Member promoted to admin successfully" })
      end

      # PUT /api/v1/projects/:id/members/:user_id/demote
      def demote_member
        user = User.find(params[:user_id])
        membership = @project.project_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this project", :not_found)
        end

        if membership.owner?
          return render_error("Cannot demote project owner")
        end

        if membership.member?
          return render_error("User is already a member")
        end

        membership.update!(role: :member)
        render_success({ message: "Admin demoted to member successfully" })
      end

      private

      def set_project
        @project = current_user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", :not_found)
      end

      def ensure_member_access
        unless member_of_project?(@project)
          render_unauthorized("You must be a member of this project to view it")
        end
      end

      def ensure_admin_access
        unless admin_of_project?(@project)
          render_unauthorized("You must be an admin or owner of this project to perform this action")
        end
      end

      def ensure_owner_access
        unless owner_of_project?(@project)
          render_unauthorized("You must be the owner of this project to perform this action")
        end
      end

      def project_params
        params.require(:project).permit(:name, :description)
      end
    end
  end
end
