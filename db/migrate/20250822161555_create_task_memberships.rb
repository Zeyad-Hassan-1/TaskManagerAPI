class CreateTaskMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :task_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end
  end
end
