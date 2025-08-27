class Api::V1::InvitationsController < Api::ApplicationController
  include Notifiable

  before_action :set_invitation, only: [ :update, :destroy ]

  # GET /api/v1/invitations
  def index
    @invitations = current_user.received_invitations.where(status: "pending")
    render_success(@invitations)
  end

  # PUT /api/v1/invitations/:id
  def update
    ActiveRecord::Base.transaction do
      if @invitation.update(status: params[:status])
        if @invitation.accepted?
          add_user_to_membership
          create_notification(@invitation.inviter, @invitation, "accepted")
        else
          create_notification(@invitation.inviter, @invitation, "declined")
        end
        render_success({ message: "Invitation #{params[:status]} successfully." })
      else
        render_error(@invitation.errors.full_messages.join(", "))
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error updating invitation #{@invitation&.id}: #{e.message}")
    render_error("An error occurred while processing your request", :internal_server_error)
  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation.destroy
    render_success({ message: "Invitation declined." })
  end

  private

  def set_invitation
    @invitation = current_user.received_invitations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Invitation not found", :not_found)
  end

  def add_user_to_membership
    if @invitation.invitable_type == "Team"
      team = @invitation.invitable
      team_membership = team.team_memberships.create!(
        user: @invitation.invitee,
        role: @invitation.role
      )
      Rails.logger.info("User #{@invitation.invitee.username} added to team #{team.name} with role #{team_membership.role}")
    elsif @invitation.invitable_type == "Project"
      project = @invitation.invitable
      project_membership = project.project_memberships.create!(
        user: @invitation.invitee,
        role: @invitation.role
      )
      Rails.logger.info("User #{@invitation.invitee.username} added to project #{project.name} with role #{project_membership.role}")
    else
      raise ArgumentError, "Unknown invitable type: #{@invitation.invitable_type}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create membership: #{e.message}")
    raise e
  end
end
