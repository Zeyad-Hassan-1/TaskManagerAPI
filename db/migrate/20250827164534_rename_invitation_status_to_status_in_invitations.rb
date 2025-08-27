class RenameInvitationStatusToStatusInInvitations < ActiveRecord::Migration[8.0]
  def change
    rename_column :invitations, :invitation_status, :status
  end
end
