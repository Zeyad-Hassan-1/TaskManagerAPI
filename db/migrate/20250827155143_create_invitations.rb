class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :inviter, polymorphic: true, null: false
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true
      t.references :project, foreign_key: true
      t.string :status, default: 'pending'
      t.string :role

      t.timestamps
    end
  end
end
