class RenameDiscriptionToDescriptionInProjects < ActiveRecord::Migration[8.0]
  def change
    rename_column :projects, :discription, :description
  end
end
