class Api::V1::InvitationsController < Api::ApplicationController
  include Notifiable

  before_action :set_invitation, only: [ :update, :destroy ]

  # GET /api/v1/invitations
  def index
    @invitations = current_user.received_invitations.where(status: "pending")

    serialized_invitations = @invitations.map do |invitation|
      InvitationSerializer.new(invitation).serializable_hash
    end

    render json: { data: serialized_invitations }, status: :ok
  end

  # PUT /api/v1/invitations/:id
  def update
    ActiveRecord::Base.transaction do
      if @invitation.update(status: params[:status])
        if @invitation.accepted?
          add_user_to_membership
          create_notification(@invitation.inviter, @invitation.invitable, "accepted")
        else
          create_notification(@invitation.inviter, @invitation.invitable, "declined")
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
      team_membership = team.team_memberships.find_or_create_by(user: @invitation.invitee) do |tm|
        tm.role = @invitation.role
      end

      # Notify all team members about the new member
      team.users.where.not(id: @invitation.invitee.id).each do |member|
        create_notification(member, team, "member_joined")
      end

      Rails.logger.info("User #{@invitation.invitee.username} added to team #{team.name} with role #{team_membership.role}")
    elsif @invitation.invitable_type == "Project"
      project = @invitation.invitable
      project_membership = project.project_memberships.find_or_create_by(user: @invitation.invitee) do |pm|
        pm.role = @invitation.role
      end

      # Notify all project members about the new member
      project.users.where.not(id: @invitation.invitee.id).each do |member|
        create_notification(member, project, "member_joined")
      end

      Rails.logger.info("User #{@invitation.invitee.username} added to project #{project.name} with role #{project_membership.role}")
    else
      raise ArgumentError, "Unknown invitable type: #{@invitation.invitable_type}"
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create membership: #{e.message}")
    raise e
  end
end
