class AddStatusToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :status, :integer, default: 0, null: false
    add_index :projects, :status
  end
end
