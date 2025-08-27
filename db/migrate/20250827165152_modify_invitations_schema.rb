class ModifyInvitationsSchema < ActiveRecord::Migration[8.0]
  def change
    remove_reference :invitations, :inviter, polymorphic: true, null: false
    add_reference :invitations, :inviter, foreign_key: { to_table: :users }
    add_reference :invitations, :invitable, polymorphic: true, null: false
  end
end
