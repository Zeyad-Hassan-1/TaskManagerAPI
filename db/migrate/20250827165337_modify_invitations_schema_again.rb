class ModifyInvitationsSchemaAgain < ActiveRecord::Migration[8.0]
  def up
    remove_column :invitations, :team_id
    remove_column :invitations, :project_id
  end

  def down
    add_reference :invitations, :team, foreign_key: true
    add_reference :invitations, :project, foreign_key: true
  end
end
