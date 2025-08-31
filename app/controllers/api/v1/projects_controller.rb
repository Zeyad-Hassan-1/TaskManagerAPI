module Api
  module V1
    class ProjectsController < Api::ApplicationController
      include Authorizable
      include Notifiable

      before_action :set_project, only: [ :show, :update, :destroy, :invite_member, :remove_member, :promote_member, :demote_member, :add_comment, :remove_comment, :add_tag, :remove_tag, :add_attachment, :remove_attachment ]
      before_action :ensure_member_access, only: [ :show, :add_comment, :add_tag, :add_attachment ]
      before_action :ensure_admin_access, only: [ :update, :invite_member, :remove_comment, :remove_tag, :remove_attachment ]
      before_action :ensure_owner_access, only: [ :destroy, :remove_member, :promote_member, :demote_member ]

      # GET /api/v1/teams/:team_id/projects
      def index
        begin
          @team = Team.find(params[:team_id])
        rescue ActiveRecord::RecordNotFound
          return render_error("Team not found", :not_found)
        end

        # Check if user is a member of the team
        unless member_of_team?(@team)
          return render_unauthorized("You must be a member of this team to view its projects")
        end

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
        begin
          @team = Team.find(params[:team_id])
        rescue ActiveRecord::RecordNotFound
          return render_error("Team not found", :not_found)
        end

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

        # Check if user is a member of the team that owns this project
        unless @project.team.team_memberships.exists?(user: invitee)
          return render_error("User must be a member of the team to be invited to projects")
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

      # POST /api/v1/projects/:id/comments
      def add_comment
        comment = @project.comments.build(comment_params)
        comment.user = current_user

        if comment.save
          serialized_comment = CommentSerializer.new(comment).serializable_hash
          render json: { data: serialized_comment }, status: :created
        else
          render_error(comment.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/projects/:id/comments/:comment_id
      def remove_comment
        comment = @project.comments.find(params[:comment_id])

        # Only allow user to delete their own comments or admin/owner can delete any
        unless comment.user == current_user || admin_of_project?(@project)
          return render_unauthorized("You can only delete your own comments")
        end

        comment.destroy
        render_success({ message: "Comment deleted successfully" })
      end

      # POST /api/v1/projects/:id/tags
      def add_tag
        tag = Tag.find_or_create_by(name: params[:name].strip.downcase)

        unless @project.tags.include?(tag)
          @project.tags << tag
          serialized_tag = TagSerializer.new(tag).serializable_hash
          render json: { data: serialized_tag }, status: :created
        else
          render_error("Tag already exists on this project")
        end
      end

      # DELETE /api/v1/projects/:id/tags/:tag_id
      def remove_tag
        tag = @project.tags.find(params[:tag_id])
        @project.tags.delete(tag)
        render_success({ message: "Tag removed successfully" })
      end

      # POST /api/v1/projects/:id/attachments
      def add_attachment
        attachment = @project.attachments.build(attachment_params)
        attachment.user = current_user

        if attachment.save
          serialized_attachment = AttachmentSerializer.new(attachment).serializable_hash
          render json: { data: serialized_attachment }, status: :created
        else
          render_error(attachment.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/projects/:id/attachments/:attachment_id
      def remove_attachment
        attachment = @project.attachments.find(params[:attachment_id])

        # Only allow user to delete their own attachments or admin/owner can delete any
        unless attachment.user == current_user || admin_of_project?(@project)
          return render_unauthorized("You can only delete your own attachments")
        end

        attachment.destroy
        render_success({ message: "Attachment deleted successfully" })
      end

      private

      def set_project
        @project = Project.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Project not found", :not_found)
      end

      def ensure_member_access
        # Allow access if user is either a project member OR a team member
        unless member_of_project?(@project) || member_of_team?(@project.team)
          render_unauthorized("You must be a member of this project or its team to view it")
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
        params.require(:project).permit(:name, :description, :status)
      end

      def comment_params
        params.require(:comment).permit(:content)
      end

      def attachment_params
        params.permit(:file, :link, :name)
      end
    end
  end
end
