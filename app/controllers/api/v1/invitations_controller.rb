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
      team.team_memberships.create!(user: @invitation.invitee, role: @invitation.role)
    elsif @invitation.invitable_type == "Project"
      project = @invitation.invitable
      project.project_memberships.create!(user: @invitation.invitee, role: @invitation.role)
    end
  end
end
