class RenameStatusInInvitations < ActiveRecord::Migration[8.0]
  def change
    rename_column :invitations, :status, :invitation_status
  end
end
