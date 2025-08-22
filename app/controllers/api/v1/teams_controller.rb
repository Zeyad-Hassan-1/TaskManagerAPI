module Api
  module V1
    class TeamsController < Api::ApplicationController
      before_action :set_team, only: [ :show, :update, :destroy ]

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
        @team = Team.new(team_params)

        if @team.save
          # Create team membership for the creator
          TeamMembership.create!(
            user: current_user,
            team: @team,
            role: :owner
          )
          render_success(@team, :created)
        else
          render_error(@team.errors.full_messages.join(", "))
        end
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

      private

      def set_team
        @team = current_user.teams.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error("Team not found", :not_found)
      end

      def team_params
        params.require(:team).permit(:name, :discription)
      end
    end
  end
end
