class RenameDiscriptionToDescriptionInTeams < ActiveRecord::Migration[8.0]
  def change
    rename_column :teams, :discription, :description
  end
end
