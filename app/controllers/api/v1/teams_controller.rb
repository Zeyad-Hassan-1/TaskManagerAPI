module Api
  module V1
    class TeamsController < Api::ApplicationController
      include Authorizable

      before_action :set_team, only: [ :show, :update, :destroy, :invite_member, :remove_member, :promote_member, :demote_member ]
      before_action :ensure_member_access, only: [ :show ]
      before_action :ensure_admin_access, only: [ :update, :invite_member ]
      before_action :ensure_owner_access, only: [ :destroy, :remove_member, :promote_member, :demote_member ]

      # GET /api/v1/teams
      def index
        @teams = current_user.teams
        render_success(@teams)
      end

      # GET /api/v1/teams/:id
      def show
        render_success(@team)
      end

      # POST /api/v1/teams
      def create
        ActiveRecord::Base.transaction do
          @team = Team.create!(team_params)
          @team.team_memberships.create!(user: current_user, role: :owner)
        end
          render_success(@team, :created)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.message)
      end

      # PUT /api/v1/teams/:id
      def update
        if @team.update(team_params)
          render_success(@team)
        else
          render_error(@team.errors.full_messages.join(", "))
        end
      end

      # DELETE /api/v1/teams/:id
      def destroy
        @team.destroy
        render_success({ message: "Team deleted successfully" })
      end

      # POST /api/v1/teams/:id/invite
      def invite_member
        user = User.find_by(username: params[:username])

        unless user
          return render_error("User not found", :not_found)
        end

        if @team.team_memberships.exists?(user: user)
          return render_error("User is already a member of this team")
        end

        role = params[:role] || "member"
        unless [ "member", "admin" ].include?(role)
          return render_error("Invalid role. Must be 'member' or 'admin'")
        end

        @team.team_memberships.create!(
          user: user,
          role: role
        )

        render_success({ message: "User invited successfully" }, :created)
      end

      # DELETE /api/v1/teams/:id/members/:user_id
      def remove_member
        user = User.find(params[:user_id])
        membership = @team.team_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this team", :not_found)
        end

        if membership.owner?
          return render_error("Cannot remove team owner")
        end

        membership.destroy
        render_success({ message: "Member removed successfully" })
      end

      # PUT /api/v1/teams/:id/members/:user_id/promote
      def promote_member
        user = User.find(params[:user_id])
        membership = @team.team_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this team", :not_found)
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

      # PUT /api/v1/teams/:id/members/:user_id/demote
      def demote_member
        user = User.find(params[:user_id])
        membership = @team.team_memberships.find_by(user: user)

        unless membership
          return render_error("User is not a member of this team", :not_found)
        end

        if membership.owner?
          return render_error("Cannot demote team owner")
        end

        if membership.member?
          return render_error("User is already a member")
        end

        membership.update!(role: :member)
        render_success({ message: "Admin demoted to member successfully" })
      end

      private

      def set_team
        @team = current_user.teams.includes(:users, :team_memberships).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Team not found", :not_found)
      end

      def ensure_member_access
        unless member_of_team?(@team)
          render_unauthorized("You must be a member of this team to view it")
        end
      end

      def ensure_admin_access
        unless admin_of_team?(@team)
          render_unauthorized("You must be an admin or owner of this team to perform this action")
        end
      end

      def ensure_owner_access
        unless owner_of_team?(@team)
          render_unauthorized("You must be the owner of this team to perform this action")
        end
      end

      def team_params
        params.permit(:name, :description)
      end
    end
  end
end
